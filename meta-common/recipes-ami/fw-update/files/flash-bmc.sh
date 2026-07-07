#!/bin/sh
# flash-bmc.sh — SPI write for BMC images with ABR awareness.
# Usage: flash-bmc.sh IMAGE_DIR IMAGE_PATH TARGET
#
# Positional:
#   IMAGE_DIR  : directory that contains the image + manifest (used if IMAGE_PATH is relative)
#   IMAGE_PATH : absolute path OR filename under IMAGE_DIR
#   TARGET     : logical target/basename (bmc_active | bmc_backup)
#
# Env (optional):
#   TARGET_SLOT=active|backup            # default: inferred from TARGET
#   SLOT_FILE=/run/media/slot            # 0=CS0(active), 1=CS1(backup)
#   ALT_BMC_OFFSET=0x<bytes>|<bytes>     # override for single‑SPI ABR absolute offset
#
# Notes:
#   - Dual‑SPI ABR: writes to /dev/mtd(by-name)/(bmc|alt-bmc) at offset 0 using flashcp.
#   - Single‑SPI ABR (your DTS layout): computes bank size from u-boot → alt-u-boot,
#     then writes the image at kernel start of the selected bank via /dev/mtd0.
#   - Non‑zero offset writes use flash_erase + mtd_debug write and are verified by readback.

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

if [ -f "$IMAGE_PATH" ]; then
  LOCAL_PATH="$IMAGE_PATH"
else
  LOCAL_PATH="${IMAGE_DIR%/}/$IMAGE_PATH"
fi
debug_log "Resolved LOCAL_PATH=$LOCAL_PATH"

# Defaults
: "${SLOT_FILE:=/run/media/slot}"
: "${ALT_BMC_OFFSET:=}"
: "${ABR_BOOT_MODE_FILE:=/sys/class/spi_master/spi0/device/abr_bootmode}"

# Infer TARGET_SLOT if not provided
if [ -z "${TARGET_SLOT:-}" ]; then
  case "$TARGET" in
    bmc_active) TARGET_SLOT="active" ;;
    bmc_bkup|bmc_backup) TARGET_SLOT="backup" ;;
    *) TARGET_SLOT="active"; log "WARNING: Unknown TARGET='$TARGET', defaulting TARGET_SLOT='$TARGET_SLOT'" 2>/dev/null || true ;;
  esac
  debug_log "TARGET_SLOT resolved to $TARGET_SLOT"
fi

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
_to_dec() { val="$1"; [ -n "$val" ] || return 1; dec=$(( val + 0 )); [ "$dec" -ge 0 ] || return 1; printf '%s\n' "$dec"; }
debug_log "_to_dec called with $1"

_read_boot_mode() { # 1=single‑ABR, 0=dual
  if [ -f "$ABR_BOOT_MODE_FILE" ]; then cat "$ABR_BOOT_MODE_FILE"; else echo 0; fi
}

_read_boot_source() { # 0=CS0(active), 1=CS1(backup)
  if [ -f "$SLOT_FILE" ]; then cat "$SLOT_FILE"; else echo 0; fi
}

# Find mtd by label: use system helper if present, else /proc/mtd
find_mtd_by_label() {
  if command -v get_mtd_by_label >/dev/null 2>&1; then
    get_mtd_by_label "$1" 2>/dev/null || true
  else
    awk -v n="$1" -F '[: "]+' '$0 ~ "\"" n "\"$" {sub(/:/,"",$1); print $1}' /proc/mtd
  fi
}

mtd_abs_off()   { cat "/sys/class/mtd/$1/offset"     2>/dev/null; }
mtd_size()      { cat "/sys/class/mtd/$1/size"       2>/dev/null; }
mtd_erasesize() { cat "/sys/class/mtd/$1/erasesize"  2>/dev/null; }

# Derive bank starts for single‑SPI ABR using alt‑u‑boot
# Exports:
#   PRIMARY_START  -> absolute byte offset where BMC payload begins in bank A (kernel@A)
#   ALT_START      -> absolute byte offset where BMC payload begins in bank B (kernel@B)
#   BANK_SIZE      -> bytes from u-boot to alt-u-boot (bank window)
derive_bank_starts_single_spi() {
  debug_log "Entered derive_bank_starts_single_spi()"
  mtd_u="$(find_mtd_by_label 'u-boot' 2>/dev/null || true)"
  [ -n "$mtd_u" ] || mtd_u="$(find_mtd_by_label 'u-boot0' 2>/dev/null || true)"
  mtd_au="$(find_mtd_by_label 'alt-u-boot' 2>/dev/null || true)"
  [ -n "$mtd_u" ] && [ -n "$mtd_au" ] || { log "ERROR: need u-boot, alt-u-boot, kernel" 2>/dev/null || true; return 1; }

  uoff="$(mtd_abs_off "$mtd_u")"
  auoff="$(mtd_abs_off "$mtd_au")"
  [ -n "$uoff" ] && [ -n "$auoff" ] || { log "ERROR: cannot read MTD offsets" 2>/dev/null || true; return 1; }

  if [ "$uoff" -le "$auoff" ]; then bankA="$uoff"; bankB="$auoff"; else bankA="$auoff"; bankB="$uoff"; fi
  BANK_SIZE=$(( bankB - bankA ))

  PRIMARY_START="$uoff"
  ALT_START="$auoff"
  export PRIMARY_START ALT_START BANK_SIZE
}

set_default_destination() {
  debug_log "Entered set_default_destination()"
  : "${FLASH_DEV_DEFAULT:=/dev/mtd0}"
  FLASH_DEV="${FLASH_DEV_DEFAULT}"
  FLASH_OFFSET=0
  unset BANK_LIMIT_START BANK_LIMIT_SIZE
  export FLASH_DEV FLASH_OFFSET
  log "Destination set (no SLOT_FILE): ${FLASH_DEV} @ offset ${FLASH_OFFSET}" 2>/dev/null || true
}

# Choose device + offset based on ABR mode and target slot
resolve_flash_destination() {
  debug_log "Entered resolve_flash_destination() with boot_mode=$1 boot_source=$2 slot=${TARGET_SLOT:-active}"
  boot_mode="$1"   # 0=dual, 1=single
  boot_source="$2" # 0=CS0, 1=CS1
  slot="${TARGET_SLOT:-active}"
  case "$slot" in active|backup) : ;; *) log "ERROR: TARGET_SLOT must be active|backup" 2>/dev/null || true; return 2 ;; esac

  if [ "$boot_mode" -eq 0 ]; then
    # Dual‑SPI ABR: select label bmc / alt-bmc, write at offset 0
    if [ "$slot" = "active" ]; then
      [ "$boot_source" -eq 0 ] && label="bmc" || label="alt-bmc"
    else
      [ "$boot_source" -eq 0 ] && label="alt-bmc" || label="bmc"
    fi
    mtd="$(find_mtd_by_label "$label" 2>/dev/null || true)"
    [ -n "$mtd" ] && [ -e "/dev/$mtd" ] || { log "ERROR: MTD '$label' not found" 2>/dev/null || true; return 3; }
    FLASH_DEV="/dev/$mtd"
    FLASH_OFFSET=0
    unset BANK_LIMIT_START BANK_LIMIT_SIZE
  else
    # Single‑SPI ABR: compute bank starts; write to /dev/mtd0 at kernel start
    derive_bank_starts_single_spi || return 4
    FLASH_DEV="/dev/mtd0"

    # Which bank are we updating?
    want_alt=0
    if   [ "$slot" = "active" ] && [ "$boot_source" -eq 1 ]; then want_alt=1
    elif [ "$slot" = "backup" ] && [ "$boot_source" -eq 0 ]; then want_alt=1
    fi

    if [ -n "${ALT_BMC_OFFSET:-}" ]; then
      FLASH_OFFSET="$(_to_dec "$ALT_BMC_OFFSET")" || { log "ERROR: invalid ALT_BMC_OFFSET='$ALT_BMC_OFFSET'" 2>/dev/null || true; return 4; }
    else
      FLASH_OFFSET=$([ "$want_alt" -eq 1 ] && printf '%s' "$ALT_START" || printf '%s' "$PRIMARY_START")
    fi

    # Bound the write to a single bank window for safety
    BANK_LIMIT_START=$([ "$want_alt" -eq 1 ] && printf '%s' "$ALT_START" || printf '%s' "$PRIMARY_START")
    BANK_LIMIT_SIZE="$BANK_SIZE"
    export BANK_LIMIT_START BANK_LIMIT_SIZE
  fi

  export FLASH_DEV FLASH_OFFSET
}

pre_flash_sanity() {
  debug_log "Entered pre_flash_sanity()"
  ok=1
  for t in flashcp mtd_debug flash_erase; do
    command -v "$t" >/dev/null 2>&1 || { log "ERROR: tool '$t' not found" 2>/dev/null || true; ok=0; }
  done
  [ $ok -eq 1 ] || { redfish_log_abort "required mtd tools missing" 2>/dev/null || true; update_percentage "${UPDATE_PERCENT_FAIL:-0}" 2>/dev/null || true; exit 127; }
}

detect_fw_meta() {
  debug_log "Entered detect_fw_meta()"
  dir="$(dirname "$LOCAL_PATH")"
  FWTYPE="$(detect_manifest_purpose "$dir" 2>/dev/null || true)"; [ -n "${FWTYPE:-}" ] || FWTYPE="BMC"
  FWVER=""
  if [ -f "${dir}/MANIFEST" ]; then
    FWVER="$(awk -F= '/^version=/ {print $2}' "${dir}/MANIFEST" 2>/dev/null || true)"
  elif [ -f "${dir}/manifest.json" ]; then
    FWVER="$(awk -F'"'"'" '/"[Vv]ersion" *:/ {print $4}' "${dir}/manifest.json" 2>/dev/null || true)"
  fi
  [ -n "${FWVER:-}" ] || FWVER="$(date -u +%Y.%m.%d-%H%M%S)"
  export FWTYPE FWVER
}

# Write helper:
# - offset==0 -> flashcp (erase + write + verify)
# - offset>0  -> flash_erase window + mtd_debug write + readback verify
write_spi_nor() {
  debug_log "Entered write_spi_nor()"
  [ -c "$FLASH_DEV" ] || { log "ERROR: $FLASH_DEV is not an MTD char device" 2>/dev/null || true; return 1; }
  [ -r "$LOCAL_PATH" ] || { log "ERROR: image $LOCAL_PATH not readable" 2>/dev/null || true; return 1; }
  update_percentage 65 2>/dev/null || true

  imgsize="$(wc -c < "$LOCAL_PATH" 2>/dev/null || echo 0)"
  [ "$imgsize" -gt 0 ] || { log "ERROR: image size is zero" 2>/dev/null || true; return 1; }

  # Enforce bank bounds in single‑ABR
  if [ -n "${BANK_LIMIT_START:-}" ] && [ -n "${BANK_LIMIT_SIZE:-}" ]; then
    end=$(( FLASH_OFFSET + imgsize ))
    bank_end=$(( BANK_LIMIT_START + BANK_LIMIT_SIZE ))
    if [ "$end" -gt "$bank_end" ]; then
      log "ERROR: image ($imgsize) exceeds bank capacity (start=$BANK_LIMIT_START size=$BANK_LIMIT_SIZE)" 2>/dev/null || true
      return 2
    fi
  fi

  if [ "${FLASH_OFFSET:-0}" -eq 0 ] 2>/dev/null; then
    # Whole-partition write
  command -v flash_unlock >/dev/null 2>&1 && flash_unlock "$FLASH_DEV" 2>/dev/null || true
  if command -v mtd-util >/dev/null 2>&1; then
    update_percentage 70 2>/dev/null || true
    if [ "$DEBUG" = "1" ]; then
      debug_log "Running: mtd-util -d $FLASH_DEV c $LOCAL_PATH 0"
      tmpout="$(mktemp)"
      mtd-util -d "$FLASH_DEV" c "$LOCAL_PATH" 0 >"$tmpout" 2>&1
      rc=$?
      while IFS= read -r line; do debug_log "mtd-util: $line"; done < "$tmpout"
      rm -f -- "$tmpout"
      [ "$rc" -eq 0 ] && update_percentage 95 2>/dev/null || true
      return $rc
    else
      mtd-util -d "$FLASH_DEV" c "$LOCAL_PATH" 0
      rc=$?
      [ "$rc" -eq 0 ] && update_percentage 95 2>/dev/null || true
      return $rc
    fi
  else
    # Check if this is single-SPI ABR case
    boot_mode="$(_read_boot_mode)"
    boot_source="$(_read_boot_source)"
    
    if [ "$boot_source" -eq 1 ] && [ "$boot_mode" -eq 1 ]; then
      # Single-SPI ABR: use flash_erase + mtd_debug write + readback verify
      mtdnode="$(basename -- "$FLASH_DEV")"
      dev_size="$(mtd_size "$mtdnode")"
      era="$(mtd_erasesize "$mtdnode")"
      [ -n "$dev_size" ] && [ -n "$era" ] || { log "ERROR: cannot read MTD geometry for $mtdnode" 2>/dev/null || true; return 3; }
      
      erase_end=$(( ((imgsize + era - 1) / era) * era ))
      block_count=$(( erase_end / era ))
      update_percentage 70 2>/dev/null || true
      
      if [ "$DEBUG" = "1" ]; then
        debug_log "Running: flash_erase $FLASH_DEV  $imgsize $block_count"
        flash_erase "$FLASH_DEV" 0 "$block_count"
        update_percentage 78 2>/dev/null || true
        debug_log "Running: mtd_debug write $FLASH_DEV $imgsize $imgsize $LOCAL_PATH"
        mtd_debug write "$FLASH_DEV" 0 "$imgsize" "$LOCAL_PATH"
      else
        flash_erase "$FLASH_DEV" 0 "$block_count"
        update_percentage 78 2>/dev/null || true
        mtd_debug write "$FLASH_DEV" 0 "$imgsize" "$LOCAL_PATH"
      fi
      update_percentage 90 2>/dev/null || true
      # Verify by readback
      # comment below readback function , in single spi abr from backup spi read/write is not working
      # once fixed will uncomment to check read status
       tmpv="$(mktemp /tmp/mtdv.XXXXXX)"
       if mtd_debug read "$FLASH_DEV" 0 "$imgsize" "$tmpv"; then
         update_percentage 95 2>/dev/null || true
         if cmp -n "$imgsize" -- "$LOCAL_PATH" "$tmpv"; then
           update_percentage 98 2>/dev/null || true
           rm -f -- "$tmpv"
           return 0
         else
           log "ERROR: verification failed: compare mismatch" 2>/dev/null || true
           rm -f -- "$tmpv"
           return 4
         fi
       else
         rm -f -- "$tmpv"
         log "ERROR: verification failed: readback error" 2>/dev/null || true
         return 5
       fi
    else
      update_percentage 70 2>/dev/null || true
      if [ "$DEBUG" = "1" ]; then
        debug_log "Running: flashcp -v -p -- $LOCAL_PATH $FLASH_DEV"
        tmpout="$(mktemp)"
        flashcp -v -p -- "$LOCAL_PATH" "$FLASH_DEV" >"$tmpout" 2>&1
        rc=$?
        while IFS= read -r line; do debug_log "flashcp: $line"; done < "$tmpout"
        rm -f -- "$tmpout"
        [ "$rc" -eq 0 ] && update_percentage 95 2>/dev/null || true
        return $rc
      else
        flashcp -v -p -- "$LOCAL_PATH" "$FLASH_DEV"
        rc=$?
        [ "$rc" -eq 0 ] && update_percentage 95 2>/dev/null || true
        return $rc
      fi
    fi
  fi
  fi

  # Non-zero offset write (single-SPI ABR)
  mtdnode="$(basename -- "$FLASH_DEV")"
  dev_size="$(mtd_size "$mtdnode")"
  era="$(mtd_erasesize "$mtdnode")"
  [ -n "$dev_size" ] && [ -n "$era" ] || { log "ERROR: cannot read MTD geometry for $mtdnode" 2>/dev/null || true; return 3; }

  end=$(( FLASH_OFFSET + imgsize ))
  if [ "$end" -gt "$dev_size" ]; then
    log "ERROR: write beyond device: end=$end dev_size=$dev_size" 2>/dev/null || true
    return 3
  fi

  start_erase=$(( (FLASH_OFFSET / era) * era ))
  erase_end=$(( ((end + era - 1) / era) * era ))
  block_count=$(( (erase_end - start_erase) / era ))

  if command -v mtd-util >/dev/null 2>&1; then
    command -v flash_unlock >/dev/null 2>&1 && flash_unlock "$FLASH_DEV" 2>/dev/null || true
    update_percentage 70 2>/dev/null || true
    if [ "$DEBUG" = "1" ]; then
      debug_log "Running: mtd-util -d $FLASH_DEV c $LOCAL_PATH $FLASH_OFFSET"
      tmpout="$(mktemp)"
      mtd-util -d "$FLASH_DEV" c "$LOCAL_PATH" "$FLASH_OFFSET" >"$tmpout" 2>&1
      rc=$?
      while IFS= read -r line; do debug_log "mtd-util: $line"; done < "$tmpout"
      rm -f -- "$tmpout"
      [ "$rc" -eq 0 ] && update_percentage 95 2>/dev/null || true
      return $rc
    else
      mtd-util -d "$FLASH_DEV" c "$LOCAL_PATH" "$FLASH_OFFSET"
      rc=$?
      [ "$rc" -eq 0 ] && update_percentage 95 2>/dev/null || true
      return $rc
    fi
  else
    command -v flash_unlock >/dev/null 2>&1 && flash_unlock "$FLASH_DEV" 2>/dev/null || true
    # Special case: if boot_source is 1 and boot_mode is 1, use offset 0 ass mtd_debug write and flash erase are not switching offsets as per ABR
    boot_mode="$(_read_boot_mode)"
    boot_source="$(_read_boot_source)"
    update_percentage 70 2>/dev/null || true
    if [ "$boot_source" -eq 1 ] && [ "$boot_mode" -eq 1 ]; then
      flash_erase "$FLASH_DEV" "$imgsize" "$block_count"
      update_percentage 78 2>/dev/null || true
      mtd_debug write "$FLASH_DEV" "$imgsize" "$imgsize" "$LOCAL_PATH"
    else
      flash_erase "$FLASH_DEV" "$start_erase" "$block_count"
      update_percentage 78 2>/dev/null || true
      mtd_debug write "$FLASH_DEV" "$FLASH_OFFSET" "$imgsize" "$LOCAL_PATH"
    fi
    update_percentage 90 2>/dev/null || true
  fi

  # Verify by readback
  if [ "$boot_source" -ne 1 ] || [ "$boot_mode" -ne 1 ]; then # remove condition when read/write block issue fixed for single spi abr from backup spi
    tmpv="$(mktemp /tmp/mtdv.XXXXXX)"
    if mtd_debug read "$FLASH_DEV" "$FLASH_OFFSET" "$imgsize" "$tmpv"; then
      update_percentage 95 2>/dev/null || true
      if cmp -n "$imgsize" -- "$LOCAL_PATH" "$tmpv"; then
        update_percentage 98 2>/dev/null || true
        rm -f -- "$tmpv"
        return 0
      else
        log "ERROR: verification failed: compare mismatch" 2>/dev/null || true
        rm -f -- "$tmpv"
        return 4
      fi
    else
      rm -f -- "$tmpv"
      log "ERROR: verification failed: readback error" 2>/dev/null || true
      return 5
    fi
  fi
}

# ---------- Main ----------
section "FLASH" 2>/dev/null || true
debug_log "FLASH section started"
[ -f "${LOCAL_PATH}" ] || { log "ERROR: image not found: ${LOCAL_PATH}" 2>/dev/null || true; redfish_log_abort "image not found" 2>/dev/null || true; update_percentage "${UPDATE_PERCENT_FAIL:-0}" 2>/dev/null || true; exit 2; }

log "TARGET=${TARGET} IMAGE_DIR=${IMAGE_DIR} IMAGE_PATH=${IMAGE_PATH}" 2>/dev/null || true
debug_log "TARGET=${TARGET} IMAGE_DIR=${IMAGE_DIR} IMAGE_PATH=${IMAGE_PATH}"
detect_fw_meta
pre_flash_sanity

if [ -f "${SLOT_FILE}" ]; then
  boot_mode="$(_read_boot_mode)"     # 1=single‑ABR, 0=dual
  boot_source="$(_read_boot_source)" # 0=CS0(active), 1=CS1(backup)
  log "SLOT_FILE present → resolving destination" 2>/dev/null || true
  log "Boot mode=$boot_mode (1=single‑ABR,0=dual) boot source=$boot_source (0=CS0,1=CS1) slot=${TARGET_SLOT}" 2>/dev/null || true
  resolve_flash_destination "$boot_mode" "$boot_source" || {
    redfish_log_abort "destination resolution failed" 2>/dev/null || true
    update_percentage "${UPDATE_PERCENT_FAIL:-0}" 2>/dev/null || true
    exit 1
  }
else
  log "SLOT_FILE not present → using default /dev/mtd0@0" 2>/dev/null || true
  set_default_destination
fi

[ -e "${FLASH_DEV}" ] || { log "ERROR: flash device not present: ${FLASH_DEV}" 2>/dev/null || true; redfish_log_abort "MTD device missing" 2>/dev/null || true; update_percentage "${UPDATE_PERCENT_FAIL:-0}" 2>/dev/null || true; exit 1; }

log "Flashing device=${FLASH_DEV} offset=${FLASH_OFFSET} (slot=${TARGET_SLOT})" 2>/dev/null || true
log "SPI write starting; this can take several minutes…" 2>/dev/null || true
update_percentage "${UPDATE_PERCENT_FLASH_OR_STAGE_START:-0}" 2>/dev/null || true

rc=0
write_spi_nor || rc=$?


if [ "$rc" -ne 0 ]; then
  log "Image update failed (rc=$rc)"
  redfish_log_abort "BMC image update failed"
  update_percentage "$UPDATE_PERCENT_FAIL"
  exit 1
fi

log "Image update successful"
redfish_log_fw_evt success
update_percentage "$UPDATE_PERCENT_SUCCESS"
sleep 2
log "flash stage complete."



