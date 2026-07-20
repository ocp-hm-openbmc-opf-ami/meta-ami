#!/bin/sh
# flash-nvme.sh — NVMe controller firmware update (aligned with common.sh style)
# Usage: flash-nvme.sh IMAGE_DIR IMAGE_PATH TARGET
#   TARGET examples:
#     NVMe_64
#     NVMe_8
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
    log "ERROR: NVMe flash aborted (rc=$rc)"
    redfish_log_abort "NVMe flash aborted"
    update_percentage "$UPDATE_PERCENT_FAIL"
  fi
  wait_for_log_sync
  exit $rc
' ERR INT HUP

# ---- helpers -----------------------------------------------------------------
pre_nvme_sanity() {
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

show_nvme_journal_tail() {
  log "NVMe journal tail (last 20 lines)"
  if command -v journalctl >/dev/null 2>&1; then
    journalctl 2>/dev/null | grep nvme | tail -20 || true
  else
    log "WARN: journalctl not found; cannot print NVMe logs"
  fi
}

set_fw_meta_nvme() {
  local dir
  dir="$(dirname "${LOCAL_PATH}")"
  FWTYPE="NVME"
  FWVER=""
  if [ -f "$dir/MANIFEST" ]; then
    FWVER="$(awk -F= '/^version=/ {print $2}' "$dir/MANIFEST" 2>/dev/null || true)"
  fi
  [ -n "$FWVER" ] || FWVER="NA"
  export FWTYPE FWVER
}

# No-op placeholder; upstream logic may clear busy/targets in fwupd.sh
Clear_pushuri_target_and_busy_status() { :; }

# ---- main -------------------------------------------------------------------
section "NVME FLASH"
[ -f "${LOCAL_PATH}" ] || { log "ERROR: image not found: ${LOCAL_PATH}"; redfish_log_abort "NVMe image not found"; update_percentage "$UPDATE_PERCENT_FAIL"; exit 2; }

set_fw_meta_nvme
pre_nvme_sanity
ensure_stdbuf

update_percentage "$UPDATE_PERCENT_PRESTAGE_VERIFY_START"
update_percentage "$UPDATE_PERCENT_FLASH_OR_STAGE_START"

# Support multiple targets space-separated
if [ -n "$TARGET_IN" ]; then
  set -- $TARGET_IN
  updaterList="$*"
else
  log "ERROR: No NVMe target passed; please invoke with a single target (e.g., NVMe_64)"
  redfish_log_abort "No NVMe target provided"
  update_percentage "$UPDATE_PERCENT_FAIL"
  exit 1
fi

rc_all=0
nvme_service="xyz.openbmc_project.NVMEMgt"
nvme_object="/xyz/openbmc_project/software/"
nvme_interface="xyz.openbmc_project.Software.Update"
nvme_fw_method="firmwareUpdate"

for targetPath in $updaterList; do
    log "Start $targetPath NVMe Firmware update"

    id="${targetPath#NVMe_}"
    if [ -z "$id" ] || [ "$id" = "$targetPath" ] || ! echo "$id" | grep -Eq '^[0-9]+$'; then
      log "ERROR: Invalid NVMe target format: $targetPath (expected NVMe_<id>)"
      redfish_log_abort "Invalid NVMe target: $targetPath"
      rc_all=1
      continue
    fi

    # call busctl to trigger the update; this will be picked up by fwupd's NVMe plugin
    if busctl --timeout=300 call \
        "$nvme_service" \
        "${nvme_object}${targetPath}" \
        "$nvme_interface" \
        "$nvme_fw_method" \
        ysb "$id" "$LOCAL_PATH" true; then
      rc=0
      log "NVMe firmware updated successfully for $targetPath"
      show_nvme_journal_tail
    else
      rc=$?
      log "ERROR: NVMe firmware update failed for $targetPath (rc=$rc)"
      show_nvme_journal_tail
      redfish_log_abort "NVMe firmware update failed for $targetPath"
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
  log "NVMe firmware update complete"
  exit 0
else
  redfish_log_abort "NVMe firmware update failed"
  exit 1
fi
  