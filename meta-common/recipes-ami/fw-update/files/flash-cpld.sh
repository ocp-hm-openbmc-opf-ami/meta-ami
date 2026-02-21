#!/bin/sh
# flash-cpld.sh — Program CPLD using cpld-tool 
# Usage: flash-cpld.sh IMAGE_DIR IMAGE_PATH TARGET
#
# Positional:
#   IMAGE_DIR  : directory that contains the image + manifest (used if IMAGE_PATH is relative/missing)
#   IMAGE_PATH : absolute path OR filename under IMAGE_DIR
#   TARGET     : CPLD logical target/basename
#                InputParameters object : /xyz/openbmc_project/inventory/system/board/Cpld/$TARGET
#                Version set object     : /xyz/openbmc_project/software/$TARGET
#
set -eu
. /usr/libexec/fwupd/common.sh

IMAGE_DIR="${1:-}"
IMAGE_PATH="${2:-}"
TARGET="${3:-}"

# Basic arg checks
if [ -z "$IMAGE_DIR" ] || [ -z "$IMAGE_PATH" ] || [ -z "$TARGET" ]; then
  echo "Usage: $0 IMAGE_DIR IMAGE_PATH TARGET" >&2
  exit 2
fi

# Resolve LOCAL_PATH (same pattern as flash-bmc)
if [ -f "$IMAGE_PATH" ]; then
  LOCAL_PATH="$IMAGE_PATH"
else
  LOCAL_PATH="${IMAGE_DIR%/}/$IMAGE_PATH"
fi
export LOCAL_PATH

# Fixed object paths derived from TARGET (as per requirement)
CPLD_OBJ="/xyz/openbmc_project/inventory/system/board/Cpld/${TARGET}"
SW_OBJ="/xyz/openbmc_project/software/${TARGET}"

# ---- fail-safe trap ----------------------------------------------------------
trap '
  rc=$?
  if [ $rc -ne 0 ]; then
    log "ERROR: CPLD flash aborted (rc=$rc)"
    redfish_log_abort "CPLD flash aborted"
    update_percentage "$UPDATE_PERCENT_FAIL"
  fi
  wait_for_log_sync
  exit $rc
' ERR INT HUP

# ---- helpers -----------------------------------------------------------------
pre_cpld_sanity() {
  command -v cpld-tool >/dev/null 2>&1 || {
    log "ERROR: cpld-tool not found in PATH"
    redfish_log_abort "cpld-tool missing"
    update_percentage "$UPDATE_PERCENT_FAIL"
    exit 127
  }
}

# Read InputParameters from EntityManager Configuration.CPLD on the fixed object
get_cpld_input_params() {
  local obj="$1"
  local iface_cfg="xyz.openbmc_project.Configuration.CPLD"
  local prop="InputParameters"
  dbus_get_property_by_mapper "$obj" "$iface_cfg" "$prop" 2>/dev/null \
    | cut -d' ' -f2- | tr -d '"'
}

# Extract FWTYPE/FWVER for journald/Redfish
detect_fw_meta_cpld() {
  local dir
  dir="$(dirname "${LOCAL_PATH}")"
  FWTYPE="CPLD"
  FWVER=""
  if [ -f "$dir/MANIFEST" ]; then
    FWVER="$(awk -F= '/^version=/ {print $2}' "$dir/MANIFEST" 2>/dev/null || true)"
  fi
  [ -n "$FWVER" ] || FWVER="$(date -u +%Y.%m.%d-%H%M%S)"
  export FWTYPE FWVER
}

# Read USERCODE (best-effort)
read_cpld_usercode() {
  local ip="$1" out code="NA"
  if out="$(cpld-tool $ip -u 2>&1)"; then
    if echo "$out" | grep -q "Lattice USERCODE="; then
      code="$(printf '%s\n' "$out" | awk -F= '/Lattice USERCODE=/{print $2; exit}')"
    fi
  fi
  printf '%s\n' "$code"
}

# Write Software.Version.Version with USERCODE on SW_OBJ (/xyz/openbmc_project/software/$TARGET)
set_cpld_version_prop() {
  local obj="$1" usercode="$2" iface_ver="xyz.openbmc_project.Software.Version"
  local svc
  if ! svc="$(mapper_get_service "$obj" "$iface_ver" 2>/dev/null)"; then
    log "WARNING: Could not resolve service for $obj ($iface_ver); skipping Version update"
    return 0
  fi
  dbus_set_prop "$svc" "$obj" "$iface_ver" Version s "$usercode" || {
    log "WARNING: Failed to set Software.Version on $obj"
  }
}

# ---- main -------------------------------------------------------------------
section "CPLD FLASH"
[ -f "${LOCAL_PATH}" ] || {
  log "ERROR: image not found: ${LOCAL_PATH}"
  redfish_log_abort "CPLD image not found"
  update_percentage "$UPDATE_PERCENT_FAIL"
  exit 2
}

log "TARGET=${TARGET} IMAGE_DIR=${IMAGE_DIR} IMAGE_PATH=${IMAGE_PATH}"
log "CPLD inventory object: ${CPLD_OBJ}"
log "Software object      : ${SW_OBJ}"

detect_fw_meta_cpld
pre_cpld_sanity

update_percentage "$UPDATE_PERCENT_PRESTAGE_VERIFY_START"

# Ensure the InputParameters are present
ip="$(get_cpld_input_params "$CPLD_OBJ" || true)"
[ -n "$ip" ] || {
  log "ERROR: Failed to read CPLD InputParameters for $CPLD_OBJ"
  redfish_log_abort "CPLD InputParameters missing"
  update_percentage "$UPDATE_PERCENT_FAIL"
  exit 1
}

log "CPLD Flash - Starting the cpld write…"
update_percentage "$UPDATE_PERCENT_FLASH_OR_STAGE_START"

cmd="cpld-tool $ip -p $LOCAL_PATH"
log "issuing... $cmd"

cpld_out=""
if ! cpld_out="$(cpld-tool $ip -p "$LOCAL_PATH" 2>&1)"; then
  rc=$?
  log "CPLD Flash - Image update failed (rc=$rc)"
  log "$cpld_out"
  redfish_log_abort "CPLD image update failed"
  update_percentage "$UPDATE_PERCENT_FAIL"
  exit 1
fi

# Guard against tools that print 'failed' even on rc=0
if echo "$cpld_out" | grep -qi "failed"; then
  log "CPLD Flash - Image update reported failure"
  log "$cpld_out"
  redfish_log_abort "CPLD image update failed"
  update_percentage "$UPDATE_PERCENT_FAIL"
  exit 1
fi

update_percentage "$UPDATE_PERCENT_FLASH_OR_STAGE_COMPLETE"
log "CPLD Flash - Image update successful"

# Optional verification/readback and write back to software object
usercode="$(read_cpld_usercode "$ip")"
log "CPLD Flash - USERCODE = $usercode"
set_cpld_version_prop "$SW_OBJ" "$usercode"

redfish_log_fw_evt success
update_percentage "$UPDATE_PERCENT_SUCCESS"
sleep 1
log "cpld flash stage complete."