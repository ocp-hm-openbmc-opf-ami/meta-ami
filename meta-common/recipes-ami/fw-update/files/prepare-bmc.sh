#!/bin/sh
# Prepare step for BMC full-flash (non-Intel platforms; no PRESERVE_DIR/WHITELIST usage)
# Usage: prepare-bmc.sh 
# BusyBox ash compatible

set -eu

# Optional platform helpers (logging, fwenv_*, _is_mounted, _stop_if_active, section, update_*)
. /usr/libexec/fwupd/common.sh 2>/dev/null || true

: "${PRESERVE_LOG_PATHS:=false}"   # set 'true' if you really want /var/log/*
: "${DELETE_DISABLED_PATHS:=true}" # set 'false' to keep disabled paths

# Copy U-Boot env to /tmp/u-boot-env.bin (best effort)
backup_uboot_env_data() {
  debug_log "Entered backup_uboot_env_data()"
  : "${uboot_env_bin_file:=u-boot-env.bin}"
  # Find partition by label; fallback to /proc/mtd search
  if command -v get_mtd_by_label >/dev/null 2>&1; then
    part="$(get_mtd_by_label 'u-boot-env' 2>/dev/null || true)"
  else
    part="$(awk -F: 'tolower($2) ~ /"'"'u-boot-env'"'"$/ {gsub(/^\s+|\s+$/, "", $1); print $1}' /proc/mtd 2>/dev/null || true)"
  fi
  if [ -z "$part" ] || [ ! -e "/dev/$part" ]; then
    log "U-Boot env mtd partition not found"
    return 1
  fi
  size_dec=0
  [ -r "/sys/class/mtd/${part}/size" ] && IFS= read -r size_dec <"/sys/class/mtd/${part}/size" || true
  dest="/tmp/${uboot_env_bin_file}"
  if command -v mtd_debug >/dev/null 2>&1; then
    size_hex="$(printf "%x" "${size_dec:-0}")"
    mtd_debug read "/dev/${part}" 0 "0x${size_hex}" "$dest" >/dev/null 2>&1 || return 1
  else
    bs=4096; count=$(( (size_dec + bs - 1) / bs ))
    dd if="/dev/${part}" of="$dest" bs=$bs count=$count conv=sync,noerror >/dev/null 2>&1 || return 1
  fi
  log "U-Boot env backed up to ${dest} (${part}, size=${size_dec}B)"
  return 0
}

# Validate whitelist entries: absolute and no '..'
_is_valid_whitelist_path() {
  debug_log "Validating whitelist path: $1"
  case "$1" in /*) : ;; *) return 1 ;; esac
  case "/$1/" in */../*|*/..|../*) return 1 ;; esac
  # Optional exclusions: logs & volatile unless explicitly allowed
  case "$1" in /var/log/*|/var/volatile/*) [ "$PRESERVE_LOG_PATHS" = "true" ] || return 1 ;; esac
  return 0
}

Check_and_update_whitelist() {

  debug_log "Entered Check_and_update_whitelist()"
  service="xyz.openbmc_project.EntityManager"
  interface="xyz.openbmc_project.Configuration.Preserve"

  # Build list of config objects
  config_list=$(busctl tree --list "$service" 2>/dev/null | awk '/Configuration\//{print $0}')

  # Ensure whitelist exists and is empty
  local whitelist="$1"
  local blacklist_file="$2"
  wl_dir="${whitelist%/*}"; [ "$wl_dir" != "$whitelist" ] && [ -n "$wl_dir" ] && mkdir -p -- "$wl_dir" || true
  : > "$whitelist"
  debug_log "Whitelist prepared at $whitelist"

  IS_UBOOT_ENABLED=false
  enabled_mods=""; disabled_mods=""

  for config_obj in $config_list; do
    debug_log "Processing config object: $config_obj"
    base="${config_obj##*/}"
    isEnable=$(busctl get-property "$service" "$config_obj" "$interface" isEnable 2>/dev/null | awk '{print $2}')
    filespath=$(busctl get-property "$service" "$config_obj" "$interface" filepath 2>/dev/null | awk -F'"' '{for(i=2;i<=NF;i+=2) print $i}')

    # How many paths were requested by this module?
    req_count=$(printf '%s\n' "$filespath" | sed '/^$/d' | wc -l | awk '{print $1}')
    kept_count=0

    if [ -n "$isEnable" ] && [ "$isEnable" = "true" ]; then
      debug_log "Preserve ENABLED for: $base"
      # Filter, log, and append paths (stay in same shell to keep counters)
      tmp_wl=$(mktemp)
      IFS='
'
      for p in $filespath; do
        debug_log "Checking preserve path: $p"
        [ -n "$p" ] || continue
        if _is_valid_whitelist_path "$p"; then
          debug_log "Preserved path: $p"
          printf '%s\n' "$p" >> "$tmp_wl"
          kept_count=$((kept_count + 1))
          [ "${PRESERVE_LOG_PATHS:-false}" = "true" ] && log "  + $p"
        else
          debug_log "Skipped invalid preserve path: $p"
          echo "WARNING: Skipping invalid preserve path: $p" >&2
        fi
      done
      unset IFS

      [ -s "$tmp_wl" ] && cat "$tmp_wl" >> "$whitelist"
  debug_log "Appended preserved paths to whitelist: $tmp_wl"
      rm -f -- "$tmp_wl"

      enabled_mods="$enabled_mods $base"
      log "Preserve ENABLED: $base (requested=$req_count, kept=$kept_count)"

      if [ "$base" = "U_BOOT_ENV" ]; then
        debug_log "U_BOOT_ENV detected; backing up u-boot-env partition"
        log "BMC Full Flash - Backup u-boot-env partition"
        backup_uboot_env_data || log "WARNING: u-boot-env backup failed"
        IS_UBOOT_ENABLED=true
        command -v fwenv_persist >/dev/null 2>&1 && fwenv_persist IS_UBOOT_ENABLED || true
      fi
    else
      debug_log "Preserve DISABLED for: $base"
      disabled_mods="$disabled_mods $base"
      log "Preserve DISABLED: $base (paths=$req_count)"

      if [ "${DELETE_DISABLED_PATHS:-false}" = "true" ]; then
        debug_log "Deleting disabled preserve paths for: $base"
        for file_path in $filespath; do
          debug_log "Adding to blacklist: $file_path"
          [ -n "$file_path" ] && echo "$file_path" >> /tmp/blacklist
        done
      fi
    fi
  done

  # Summaries
  enabled_mods=$(printf '%s\n' "$enabled_mods" | sed -e 's/^ *//')
  disabled_mods=$(printf '%s\n' "$disabled_mods" | sed -e 's/^ *//')
  debug_log "Enabled modules: $enabled_mods"
  debug_log "Disabled modules: $disabled_mods"
  [ -n "$enabled_mods" ] && log "Preserve summary: ENABLED => $enabled_mods" || log "Preserve summary: ENABLED => (none)"
  [ -n "$disabled_mods" ] && log "Preserve summary: DISABLED => $disabled_mods" || log "Preserve summary: DISABLED => (none)"

  # Update preserve setting to default state
  for config_obj in $config_list; do
    isOptional=$(busctl get-property "$service" "$config_obj" "$interface" isOptional 2>/dev/null | awk '{print $2}')
    if [[ -n "$isOptional" && "$isOptional" = "true" && "${config_obj##*/}" != "U_BOOT_ENV" ]]; then
      busctl set-property "$service" "$config_obj" "$interface" isEnable b false 2>/dev/null || true
    fi
  done

  # clear file/dir entries from blacklist that are also in whitelist
  if [ -s "$whitelist" ] && [ -s "$blacklist_file" ]; then
    debug_log "Cleaning blacklist entries that are also in whitelist"
    tmp_bl=$(mktemp)
    grep -Fxv -f "$whitelist" "$blacklist_file" > "$tmp_bl" || true
    mv "$tmp_bl" "$blacklist_file"
  fi

  export IS_UBOOT_ENABLED
}

# ---- fail-safe trap --------------------------------------------------------
_fw_trap() {
  rc=$?
  if [ $rc -ne 0 ]; then
    log "ERROR: prepare stage aborted (rc=$rc)"
    command -v redfish_log_abort >/dev/null 2>&1 && redfish_log_abort "prepare stage aborted" || true
    command -v update_percentage >/dev/null 2>&1 && update_percentage "$UPDATE_PERCENT_FAIL" || true
  fi
  command -v wait_for_log_sync >/dev/null 2>&1 && wait_for_log_sync || true
  exit $rc
}
trap '_fw_trap' ERR INT HUP

# ---- main ------------------------------------------------------------------



section "PREPARE" 2>/dev/null || true
debug_log "PREPARE section started"
command -v update_status >/dev/null 2>&1 && update_status "$UPDATE_STATUS_STARTING" || true
command -v update_percentage >/dev/null 2>&1 && update_percentage "$UPDATE_PERCENT_PRESTAGE_VERIFY_START" || true

# --- Overlay/whitelist scenario detection (for both mmcblk and mtd) ---
if [ -d "/run/initramfs" ]; then
  OVERLAY_DIR="/run/initramfs/rw/cow"
  WHITELIST="/run/initramfs/whitelist"
  debug_log "Overlay scenario: /run/initramfs present, using cow and whitelist"
else
  OVERLAY_DIR="/tmp/.rwfs/.overlay"
  WHITELIST="/tmp/whitelist"
  debug_log "Overlay scenario: /run/initramfs not present, using .overlay and whitelist"
fi

# --- Detect rwfs device type and mount point ---
RWFS_MOUNT=""
RWFS_DEV=""
RWFS_TYPE="unknown"
if grep -q '/tmp/.rwfs ' /proc/mounts; then
  RWFS_MOUNT="/tmp/.rwfs"
elif grep -q '/run/initramfs/rw ' /proc/mounts; then
  RWFS_MOUNT="/run/initramfs/rw"
fi
if [ -n "$RWFS_MOUNT" ]; then
  RWFS_BACK_DEV=$(awk -v mnt="$RWFS_MOUNT" '$2==mnt {print $1}' /proc/mounts)
  case "$RWFS_BACK_DEV" in
    *mmcblk*) RWFS_TYPE="mmcblk"; debug_log "Detected rwfs device type: mmcblk (persistent) (mount: $RWFS_MOUNT, dev: $RWFS_BACK_DEV)" ;;
    *mtd*) RWFS_TYPE="mtd"; debug_log "Detected rwfs device type: mtd (volatile) (mount: $RWFS_MOUNT, dev: $RWFS_BACK_DEV)" ;;
    *) debug_log "rwfs mount $RWFS_MOUNT has unknown backing device: $RWFS_BACK_DEV" ;;
  esac
else
  debug_log "rwfs not mounted; cannot detect device type"
fi

# --- Build whitelist for both device types ---
BLACKLIST="/tmp/blacklist"
Check_and_update_whitelist "$WHITELIST" "$BLACKLIST" || true
log "Preserve policy decided: IS_UBOOT_ENABLED=${IS_UBOOT_ENABLED}"
debug_log "Preserve policy decided: IS_UBOOT_ENABLED=${IS_UBOOT_ENABLED}"

rm -rf /etc/nv-sync-enable
rm -rf /etc/sync-enable
systemctl kill xyz.openbmc_project.Software.Sync.service || true
systemctl kill nv-sync.service || true

command -v update_percentage >/dev/null 2>&1 && update_percentage "$UPDATE_PERCENT_PRESTAGE_VERIFY_COMPLETE" || true
command -v redfish_log_fw_evt >/dev/null 2>&1 && redfish_log_fw_evt start || true
log "prepare stage complete."
