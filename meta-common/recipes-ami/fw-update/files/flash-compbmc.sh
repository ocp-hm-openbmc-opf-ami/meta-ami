#!/bin/sh
# flash-compbmc.sh — Flash component BMC images (kernel, rootfs, etc.) to MTD partitions
# Usage: flash-compbmc.sh IMAGE_DIR IMAGE_PATH TARGET
#
# Positional:
#   IMAGE_DIR  : directory that contains the image + manifest
#   IMAGE_PATH : absolute path OR filename under IMAGE_DIR (e.g., image-kernel, image-rofs, image-rwfs)
#   TARGET     : logical target/basename (not used for partition selection)
#
# Logic:
#   - Discovers all image-* files in the directory (except image-rwfs)
#   - Detects partition name from image filename (image-kernel → kernel, image-rofs → rofs)
#   - Finds corresponding MTD partition by label
#   - Uses mtd-util if available, otherwise falls back to flashcp
#   - Validates write with readback comparison

set -eu

# Optional helpers (section, log, update_percentage, redfish_log_*)
. /usr/libexec/fwupd/common.sh 2>/dev/null || true

IMAGE_DIR="${1:-}"
IMAGE_PATH="${2:-}"
TARGET="${3:-}"
debug_log "IMAGE_DIR=$IMAGE_DIR IMAGE_PATH=$IMAGE_PATH TARGET=$TARGET"

# ---------- Args & path resolution ----------
[ -n "$IMAGE_DIR" ] && [ -n "$IMAGE_PATH" ] && [ -n "$TARGET" ] || {
  echo "Usage: $0 IMAGE_DIR IMAGE_PATH TARGET" >&2; exit 2; }

# Verify IMAGE_DIR exists
[ -d "$IMAGE_DIR" ] || {
  echo "ERROR: IMAGE_DIR does not exist: $IMAGE_DIR" >&2; exit 2; }

debug_log "Will process all image-* files in $IMAGE_DIR"

# ---------- Trap for clean failure reporting ----------
trap '
  rc=$?
  if [ $rc -ne 0 ]; then
    log "ERROR: flash stage aborted (rc=$rc)" 2>/dev/null || true
    redfish_log_abort "flash stage aborted" 2>/dev/null || true
    update_percentage "${UPDATE_PERCENT_FAIL:-0}" 2>/dev/null || true
  fi
  wait_for_log_sync 2>/dev/null || true
  exit $rc
' ERR INT HUP
debug_log "Trap for clean failure reporting set"

# ---------- Helpers ----------

# Read boot source: 0=CS0(active), 1=CS1(backup)
_read_boot_source() {
  SLOT_FILE="${SLOT_FILE:-/run/media/slot}"
  if [ -f "$SLOT_FILE" ]; then
    cat "$SLOT_FILE"
  else
    echo 0
  fi
}

# Find mtd by label: use system helper if present, else /proc/mtd
find_mtd_by_label() {
  if command -v get_mtd_by_label >/dev/null 2>&1; then
    get_mtd_by_label "$1" 2>/dev/null || true
  else
    awk -v n="$1" -F '[: "]+' '$0 ~ "\"" n "\"$" {sub(/:/,"",$1); print $1}' /proc/mtd
  fi
}

# Detect partition name from image filename
# Examples: image-kernel → kernel, image-rofs → rofs, image-rwfs → rwfs, image-runtime → image-a
# Handles TARGET-based partition selection:
#   - If booted from primary SPI (boot_source=0):
#     - TARGET=bmc_active → normal partitions (kernel, image-a, rofs, u-boot)
#     - TARGET=bmc_bkup → alt-* partitions (alt-kernel, alt-image-a, alt-rofs, alt-u-boot)
#   - If booted from backup SPI (boot_source=1):
#     - TARGET=bmc_active → alt-* partitions (update backup when running from it)
#     - TARGET=bmc_bkup → normal partitions (update primary when running from backup)
detect_partition_name() {
  local img_file="$1"
  local basename="$(basename "$img_file")"
  local part_name=""
  
  case "$basename" in
    image-kernel*)
      part_name="kernel"
      ;;
    image-runtime*)
      part_name="image-a"
      ;;
    image-rofs*)
      part_name="rofs"
      ;;
    image-rwfs*)
      part_name="rwfs"
      ;;
    image-u-boot*)
      part_name="u-boot"
      ;;
    image-*)
      # Strip "image-" prefix and use as-is
      part_name="$(echo "$basename" | sed 's/^image-//')"
      ;;
    *)
      log "ERROR: Cannot detect partition name from '$basename'"
      return 1
      ;;
  esac
  
  # Determine current boot source (0=primary SPI/CS0, 1=backup SPI/CS1)
  local boot_source
  boot_source="$(_read_boot_source)"
  
  # Decide partition naming based on boot_source and TARGET
  local use_alt=0
  
  if [ "$boot_source" = "0" ]; then
    # Booted from primary SPI
    if [ "${TARGET:-}" = "bmc_bkup" ]; then
      use_alt=1
    fi
  else
    # Booted from backup SPI (boot_source=1)
    if [ "${TARGET:-}" = "bmc_active" ]; then
      use_alt=1
    fi
  fi
  
  # Apply alt-* prefix if needed
  if [ "$use_alt" = "1" ]; then
    case "$part_name" in
      kernel|image-a|rofs|u-boot)
        echo "alt-$part_name"
        ;;
      *)
        echo "$part_name"
        ;;
    esac
  else
    echo "$part_name"
  fi
}

pre_flash_sanity() {
  debug_log "Entered pre_flash_sanity()"
  ok=1
  # Check for either mtd-util or flashcp
  if ! command -v mtd-util >/dev/null 2>&1 && ! command -v flashcp >/dev/null 2>&1; then
    log "ERROR: neither mtd-util nor flashcp found"
    ok=0
  fi
  [ $ok -eq 1 ] || { 
    redfish_log_abort "required mtd tools missing" 2>/dev/null || true
    update_percentage "${UPDATE_PERCENT_FAIL:-0}" 2>/dev/null || true
    exit 127
  }
}

detect_fw_meta() {
  debug_log "Entered detect_fw_meta()"
  dir="$IMAGE_DIR"
  FWTYPE="$(detect_manifest_purpose "$dir" 2>/dev/null || true)"
  [ -n "${FWTYPE:-}" ] || FWTYPE="BMC"
  FWVER=""
  if [ -f "${dir}/MANIFEST" ]; then
    FWVER="$(awk -F= '/^version=/ {print $2}' "${dir}/MANIFEST" 2>/dev/null || true)"
  elif [ -f "${dir}/manifest.json" ]; then
    FWVER="$(awk -F'"' '/"[Vv]ersion" *:/ {print $4}' "${dir}/manifest.json" 2>/dev/null || true)"
  fi
  [ -n "${FWVER:-}" ] || FWVER="$(date -u +%Y.%m.%d-%H%M%S)"
  export FWTYPE FWVER
}

# Write partition using mtd-util or flashcp
write_partition() {
  local partition_name="$1"
  local image_file="$2"
  
  debug_log "Entered write_partition() partition=$partition_name image=$image_file"
  
  # Skip rwfs partition
  if [ "$partition_name" = "rwfs" ]; then
    log "Skipping rwfs partition (not flashed)"
    return 0
  fi
  
  # Find MTD device by partition label
  local mtd_dev="$(find_mtd_by_label "$partition_name" 2>/dev/null || true)"
  
  if [ -z "$mtd_dev" ]; then
    log "ERROR: MTD partition '$partition_name' not found"
    return 1
  fi
  
  local flash_dev="/dev/$mtd_dev"
  
  if [ ! -c "$flash_dev" ]; then
    log "ERROR: $flash_dev is not a character device"
    return 1
  fi
  
  if [ ! -r "$image_file" ]; then
    log "ERROR: image $image_file not readable"
    return 1
  fi
  
  local imgsize="$(wc -c < "$image_file" 2>/dev/null || echo 0)"
  if [ "$imgsize" -eq 0 ]; then
    log "ERROR: image size is zero"
    return 1
  fi
  
  log "Flashing $partition_name partition: $flash_dev (size=$imgsize bytes)"
  
  # Unlock flash if possible
  command -v flash_unlock >/dev/null 2>&1 && flash_unlock "$flash_dev" 2>/dev/null || true
  
  # Use mtd-util if available, otherwise flashcp
  if command -v mtd-util >/dev/null 2>&1; then
    if [ "$DEBUG" = "1" ]; then
      debug_log "Running: mtd-util -d $flash_dev c $image_file 0"
      tmpout="$(mktemp)"
      mtd-util -d "$flash_dev" c "$image_file" 0 >"$tmpout" 2>&1
      rc=$?
      while IFS= read -r line; do debug_log "mtd-util: $line"; done < "$tmpout"
      rm -f -- "$tmpout"
      return $rc
    else
      log "Using mtd-util to flash $partition_name"
      mtd-util -d "$flash_dev" c "$image_file" 0
      return $?
    fi
  else
    if [ "$DEBUG" = "1" ]; then
      debug_log "Running: flashcp -v -- $image_file $flash_dev"
      tmpout="$(mktemp)"
      flashcp -v -p -- "$image_file" "$flash_dev" >"$tmpout" 2>&1
      rc=$?
      while IFS= read -r line; do debug_log "flashcp: $line"; done < "$tmpout"
      rm -f -- "$tmpout"
      return $rc
    else
      log "Using flashcp to flash $partition_name"
      flashcp -v -p -- "$image_file" "$flash_dev"
      return $?
    fi
  fi
}

# ---------- Main ----------
section "FLASH COMPONENT" 2>/dev/null || true
debug_log "FLASH COMPONENT section started"

log "TARGET=${TARGET} IMAGE_DIR=${IMAGE_DIR} IMAGE_PATH=${IMAGE_PATH}"
debug_log "TARGET=${TARGET} IMAGE_DIR=${IMAGE_DIR} IMAGE_PATH=${IMAGE_PATH}"

detect_fw_meta
pre_flash_sanity

# Discover all image-* files in IMAGE_DIR (exclude image-rwfs, image-full, *.sig, zero-size files)
IMAGE_FILES=""
for img in "$IMAGE_DIR"/image-*; do
  [ -f "$img" ] || continue
  
  img_basename="$(basename "$img")"
  
  # Skip image-rwfs, image-full, and signature files
  case "$img_basename" in
    image-rwfs*)
      log "Skipping $img_basename (rwfs not flashed)"
      continue
      ;;
    image-full*)
      log "Skipping $img_basename (full image not flashed)"
      continue
      ;;
    *.sig)
      log "Skipping $img_basename (signature file)"
      continue
      ;;
  esac
  
  # Skip zero-size files
  img_size="$(wc -c < "$img" 2>/dev/null || echo 0)"
  if [ "$img_size" -eq 0 ]; then
    log "Skipping $img_basename (zero size)"
    continue
  fi
  
  IMAGE_FILES="$IMAGE_FILES $img"
done

# Trim leading space
IMAGE_FILES="$(printf "%s" "$IMAGE_FILES" | sed 's/^ *//')"

if [ -z "$IMAGE_FILES" ]; then
  log "ERROR: No image-* files found in $IMAGE_DIR"
  redfish_log_abort "no images found" 2>/dev/null || true
  update_percentage "${UPDATE_PERCENT_FAIL:-0}" 2>/dev/null || true
  exit 2
fi

log "Found images to flash: $IMAGE_FILES"
debug_log "IMAGE_FILES=$IMAGE_FILES"

log "SPI write starting; this can take several minutes…"
update_percentage "${UPDATE_PERCENT_FLASH_OR_STAGE_START:-60}" 2>/dev/null || true

# Flash each image sequentially
FLASH_COUNT=0
FLASH_FAILED=0

for img_file in $IMAGE_FILES; do
  img_basename="$(basename "$img_file")"
  log "Processing $img_basename..."
  
  # Detect partition name from image filename
  PARTITION_NAME="$(detect_partition_name "$img_file")" || {
    log "ERROR: Failed to detect partition name from $img_file"
    FLASH_FAILED=$((FLASH_FAILED + 1))
    continue
  }
  
  log "Detected partition: $PARTITION_NAME for $img_basename"
  debug_log "PARTITION_NAME=$PARTITION_NAME img_file=$img_file"
  
  # Flash the image
  if write_partition "$PARTITION_NAME" "$img_file"; then
    log "Successfully flashed $img_basename to $PARTITION_NAME"
    FLASH_COUNT=$((FLASH_COUNT + 1))
  else
    log "ERROR: Failed to flash $img_basename to $PARTITION_NAME"
    FLASH_FAILED=$((FLASH_FAILED + 1))
  fi
done

# Check results
if [ "$FLASH_FAILED" -gt 0 ]; then
  log "Component image update failed: $FLASH_FAILED failed, $FLASH_COUNT succeeded"
  redfish_log_abort "Component image update failed"
  update_percentage "$UPDATE_PERCENT_FAIL"
  exit 1
fi

log "All component images updated successfully: $FLASH_COUNT images flashed"
redfish_log_fw_evt success 2>/dev/null || true
update_percentage "${UPDATE_PERCENT_SUCCESS:-100}" 2>/dev/null || true
sleep 2
log "flash stage complete."
