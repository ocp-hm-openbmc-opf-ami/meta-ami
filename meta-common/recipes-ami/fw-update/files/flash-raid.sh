#!/bin/sh
# flash-raid.sh — RAID / HBA controller firmware update (aligned with common.sh style)
# Usage: flash-raid.sh IMAGE_DIR IMAGE_PATH TARGET
#   TARGET examples:
#     Broadcom_CTRL_1
#     Broadcom_HBA_0
#     Broadcom_Raid_0
#     Microchip_CTRL_0
#
set -eu
. /usr/libexec/fwupd/common.sh

IMAGE_DIR="${1:-}"
IMAGE_PATH="${2:-}"
TARGET_IN="${3:-}"

# Basic arg checks
if [ -z "$IMAGE_DIR" ] || [ -z "$IMAGE_PATH" ]; then
  echo "Usage: $0 IMAGE_DIR IMAGE_PATH TARGET" >&2
  exit 2
fi

# Resolve LOCAL_PATH (same pattern as other flashers)
if [ -f "$IMAGE_PATH" ]; then
  LOCAL_PATH="$IMAGE_PATH"
else
  LOCAL_PATH="${IMAGE_DIR%/}/$IMAGE_PATH"
fi
export LOCAL_PATH

# ---- fail-safe trap ----------------------------------------------------------
trap '
  rc=$?
  if [ $rc -ne 0 ]; then
    log "ERROR: RAID flash aborted (rc=$rc)"
    redfish_log_abort "RAID flash aborted"
    update_percentage "$UPDATE_PERCENT_FAIL"
  fi
  wait_for_log_sync
  exit $rc
' ERR INT HUP

# ---- helpers -----------------------------------------------------------------
pre_raid_sanity() {
  command -v busctl >/dev/null 2>&1 || {
    log "ERROR: busctl not found in PATH"; redfish_log_abort "busctl missing"; update_percentage "$UPDATE_PERCENT_FAIL"; exit 127;
  }
}

# Ensure stdbuf exists; if not, make a passthrough shim to avoid failures
ensure_stdbuf() {
  if ! command -v stdbuf >/dev/null 2>&1; then
    stdbuf() { "$@"; }
  fi
}

set_fw_meta_raid() {
  local dir
  dir="$(dirname "${LOCAL_PATH}")"
  FWTYPE="RAID"
  FWVER=""
  if [ -f "$dir/MANIFEST" ]; then
    FWVER="$(awk -F= '/^version=/ {print $2}' "$dir/MANIFEST" 2>/dev/null || true)"
  fi
  [ -n "$FWVER" ] || FWVER="NA"
  export FWTYPE FWVER
}

# No-op placeholder; upstream logic may clear busy/targets in fwupd.sh
Clear_pushuri_target_and_busy_status() { :; }

# Block on busctl monitor until terminal event; print two lines on success:
#   line1 -> ERROR_CODE   (first STRING payload seen)
#   line2 -> STATUS_MSG   (terminal status; for Microchip it's the full dotted id)
_monitor_and_get_status() {
  local vendor="$1" match="$2" to="${3:-600}"
  local first_qual="" last_plain="" val tail_segment  isMethodCompletedSignalSeen=0 is_signal_completed=0 is_error_progress=0 
  
  while IFS= read -r line <&3; do
    case "$line" in
      *MethodCompletedSignal*)
        isMethodCompletedSignalSeen=1
        ;;
    esac
    
    case "$line" in
      *string\ \"*\")
        val=$(printf '%s\n' "$line" | sed 's/.*string[[:space:]]*"\([^"]*\)".*/\1/')
        
        case "$val" in
          *ErrorCode.*)
            [ -z "$first_qual" ] && first_qual="$val"
            tail_segment=$(printf '%s\n' "$val" | awk -F'.' '{print $NF}')
            
            if [ "$vendor" = "Microchip" ]; then
              if [ "$tail_segment" != "Progress" ]; then
                is_signal_completed=1
              fi
            else
              is_signal_completed=1
            fi

            ;;
          *)
            last_plain="$val"
            if [ "$is_signal_completed" -eq 1 ]; then
              is_error_progress=1
            fi
            ;;
        esac
        ;;
    esac

    if [ "$isMethodCompletedSignalSeen" -eq 1 ] && [ "$is_signal_completed" -eq 1 ] && [ "$is_error_progress" -eq 1 ]; then
        [ -n "$first_qual" ] && printf "%s\n" "$first_qual"
        [ -n "$last_plain" ] && printf "%s\n" "$last_plain"
        return 0
    fi
  done 3< <(timeout "${to}s" dbus-monitor --system "$match")

  return 1
}

# ---- main -------------------------------------------------------------------
section "RAID FLASH"
[ -f "${LOCAL_PATH}" ] || { log "ERROR: image not found: ${LOCAL_PATH}"; redfish_log_abort "RAID image not found"; update_percentage "$UPDATE_PERCENT_FAIL"; exit 2; }

set_fw_meta_raid
pre_raid_sanity
ensure_stdbuf

update_percentage "$UPDATE_PERCENT_PRESTAGE_VERIFY_START"
update_percentage "$UPDATE_PERCENT_FLASH_OR_STAGE_START"

# Support multiple targets space-separated
if [ -n "$TARGET_IN" ]; then
  set -- $TARGET_IN
  updaterList="$*"
else
  log "ERROR: No RAID target passed; please invoke with a single target (e.g., Broadcom_CTRL_0)"
  redfish_log_abort "No RAID target provided"
  update_percentage "$UPDATE_PERCENT_FAIL"
  exit 1
fi

rc_all=0
for targetPath in $updaterList; do
  SIGNAL_RECEIVED=0

  targetRaidId="${targetPath##*_}"
  targetRAIDType="${targetPath%%_*}"
  tmp_sub="${targetPath#*_}"; targetRAIDSubType="${tmp_sub%%_*}"
  TIMEOUT=600

  log "Start $targetPath RAID Firmware update"
  debug_log " start RAID flash: type=$targetRAIDType subtype=$targetRAIDSubType id=$targetRaidId image=$LOCAL_PATH"

  case "$targetRAIDType" in
    Broadcom)
      if [ "$targetRAIDSubType" = "CTRL" ]; then
        match="type='signal',sender='com.ami.storage',member='MethodCompletedSignal'"
        run_dbus com.ami.storage /com/ami/storage/brcm8/ctrl/$targetRaidId \
          com.ami.storage.brcm8.ctrl.Configuration FlashFirmware s "$LOCAL_PATH" || true
      else
        raidSubType="$([ "$targetRAIDSubType" = "HBA" ] && echo 'HBA' || echo 'Raid')"
        raidIface="$([ "$targetRAIDSubType" = "HBA" ] && echo 'hba' || echo 'raid')"
        match="type='signal',sender='xyz.openbmc_project.${raidIface}.manager',member='MethodCompletedSignal'"
        RaidId=$(busctl get-property xyz.openbmc_project.$raidIface.manager \
                 /xyz/openbmc_project/$raidSubType/$targetRaidId \
                 xyz.openbmc_project.$raidIface.Controller Id | awk '{print $2}')
        run_dbus xyz.openbmc_project.$raidIface.manager /xyz/openbmc_project/$raidSubType \
          xyz.openbmc_project.$raidIface.Base FlashControllerFirmware us "$RaidId" "$LOCAL_PATH" || true
      fi
      ;;
    Microchip)
      match="type='signal',sender='com.ami.storage',member='MethodCompletedSignal'"
      run_dbus com.ami.storage /com/ami/storage/mscc/ctrl/$targetRaidId \
        com.ami.storage.mscc.ctrl.Configuration FlashControllerFirmware s "$LOCAL_PATH" || true
      ;;
    *)
      log "Unsupported RAID vendor in target: $targetRAIDType"; rc_all=1; continue ;;
  esac

  # Directly wait for signal and parse status (no temp files, no background PIDs)
  if out="$(_monitor_and_get_status "$targetRAIDType" "$match" "$TIMEOUT")"; then
    ERROR_CODE=$(printf '%s\n' "$out" | sed -n '1p')
    STATUS_MESSAGE=$(printf '%s\n' "$out" | sed -n '2p')
    SIGNAL_RECEIVED=1
    debug_log " RAID flash completed: status=$STATUS_MESSAGE code=${ERROR_CODE:-}"
  else
    STATUS_MESSAGE="Timeout"
    debug_log " RAID flash monitor timed out after ${TIMEOUT}s"
  fi

  update_percentage "$UPDATE_PERCENT_FLASH_OR_STAGE_COMPLETE"

  if [ "$SIGNAL_RECEIVED" -eq 1 ]; then
    is_success=0
    if [ "$targetRAIDType" = "Microchip" ]; then
      last_token=$(printf '%s' "$STATUS_MESSAGE" | awk -F'.' '{print $NF}')
      [ "$last_token" = "Success" ] && is_success=1
    else
      [ "$STATUS_MESSAGE" = "Success" ] && is_success=1
    fi

    if [ "$is_success" -eq 1 ]; then
      log "$targetPath RAID updated successfully"
    else
      log "Failed to update RAID $targetPath (status=$STATUS_MESSAGE code=${ERROR_CODE:-})"
      update_percentage "$UPDATE_PERCENT_FAIL"
      Clear_pushuri_target_and_busy_status
      rc_all=1
      break
    fi
  else
    log "Failed to receive completion signal for $targetPath"
    update_percentage "$UPDATE_PERCENT_FAIL"
    Clear_pushuri_target_and_busy_status
    rc_all=1
    break
  fi

done

if [ "$rc_all" -eq 0 ]; then
  update_percentage "$UPDATE_PERCENT_SUCCESS"
  Clear_pushuri_target_and_busy_status
  redfish_log_fw_evt success || true
  log "RAID firmware update complete"
  exit 0
else
  redfish_log_abort "RAID firmware update failed"
  exit 1
fi