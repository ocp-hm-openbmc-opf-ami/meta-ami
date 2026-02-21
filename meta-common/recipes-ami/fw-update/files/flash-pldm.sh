#!/bin/sh
# flash-pldm.sh — PLDM FW update helper (aligned with flash-bmc-intel.sh/common.sh style)
# Usage: flash-pldm.sh IMAGE_DIR IMAGE_PATH [TARGETS...]
#
# Notes:
#  * Copies the image to /tmp/images/ot-pldm/image<rand> after the dbus-monitor
#    subscription starts, to avoid missing InterfacesAdded events.
#  * Waits for a new Software object under /xyz/openbmc_project/software that
#    includes xyz.openbmc_project.Software.Activation, then requests Activation=Active
#    and monitors Activation/ActivationProgress to completion.
#
set -eu
. /usr/libexec/fwupd/common.sh

IMAGE_DIR="${1:-}"
IMAGE_PATH="${2:-}"
shift 2 || true
TARGETS="$*"   # (not used by PLDM flow; kept for parity with fwupd.sh)

# Basic arg checks
if [ -z "$IMAGE_DIR" ] || [ -z "$IMAGE_PATH" ]; then
  echo "Usage: $0 IMAGE_DIR IMAGE_PATH [TARGETS...]" >&2
  exit 2
fi

# Resolve LOCAL_PATH
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
    log "ERROR: PLDM update aborted (rc=$rc)"
    redfish_log_abort "PLDM update aborted"
    update_percentage "$UPDATE_PERCENT_FAIL"
  fi
  wait_for_log_sync
  exit $rc
' ERR INT HUP

# ---- helpers -----------------------------------------------------------------
ensure_prereqs() {
  command -v dbus-monitor >/dev/null 2>&1 || {
    log "ERROR: dbus-monitor not found"
    redfish_log_abort "dbus-monitor missing"
    update_percentage "$UPDATE_PERCENT_FAIL"
    exit 127
  }
  command -v cp >/dev/null 2>&1 || true
}

set_fw_meta_pldm() {
  local dir
  dir="$(dirname "${LOCAL_PATH}")"
  FWTYPE="PLDM"
  FWVER=""
  if [ -f "$dir/MANIFEST" ]; then
    FWVER="$(awk -F= '/^version=/ {print $2}' "$dir/MANIFEST" 2>/dev/null || true)"
  fi
  [ -n "$FWVER" ] || FWVER="NA"
  export FWTYPE FWVER
}

# Copy the image into ot-pldm directory with a randomized name
_copy_image_to_ot_pldm() {
  mkdir -p /tmp/images/ot-pldm 2>/dev/null || true
  rand=$(printf "%06d" $((RANDOM % 1000000)))
  CP_DEST="/tmp/images/ot-pldm/image${rand}"
  cp "$LOCAL_PATH" "$CP_DEST"
  export CP_DEST
  log "PLDM: image copied to $CP_DEST"
}

# Wait for InterfacesAdded with Activation interface; return object path via stdout
_wait_for_activation_object() {
  local buffer="" found=0 obj_path="" image_copied=0
  while IFS= read -r line; do
    # copy image once after monitor begins
    if [ "$image_copied" -eq 0 ]; then
      _copy_image_to_ot_pldm
      image_copied=1
    fi

    # trim
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # object path line
    if echo "$line" | grep -q '^object path'; then
      obj_path=$(echo "$line" | awk -F'"' '{print $2}')
      buffer=""
      continue
    fi

    buffer="${buffer}
${line}"

    if echo "$buffer" | grep -q "xyz.openbmc_project.Software.Activation" && [ -n "$obj_path" ]; then
      printf '%s\n' "$obj_path"
      return 0
    fi
  done < <(timeout 40s dbus-monitor --system \
       "type='signal',interface='org.freedesktop.DBus.ObjectManager',member='InterfacesAdded',path='/xyz/openbmc_project/software'")

  return 1
}

# Request Activation=Active on the PLDM object
_request_activation_active() {
  local obj="$1" svc="xyz.openbmc_project.PLDM" iface="xyz.openbmc_project.Software.Activation"
  dbus_set_prop "$svc" "$obj" "$iface" RequestedActivation s \
    xyz.openbmc_project.Software.Activation.RequestedActivations.Active || return 1
  return 0
}

# Monitor PropertiesChanged on the object until Active/Failed/etc
_monitor_activation_to_completion() {
  local obj="$1" found_progress=0
  while IFS= read -r line; do
    # progress updates
    if echo "$line" | grep -q "xyz.openbmc_project.Software.ActivationProgress"; then
      found_progress=1
    elif [ "$found_progress" = "1" ] && echo "$line" | grep -q 'variant'; then
      progress=$(echo "$line" | awk '/variant/ {print $NF}')
      case "$progress" in (*[!0-9]*) : ;; (*) update_percentage "$progress" || true ;; esac
      found_progress=0
    fi

    # activation state evaluation
    if echo "$line" | grep -q 'variant'; then
      if echo "$line" | grep -q "xyz.openbmc_project.Software.Activation.Activations.Failed"; then
        log "PLDM Activation failed"
        return 2
      elif echo "$line" | grep -q "xyz.openbmc_project.Software.Activation.Activations.Invalid"; then
        log "PLDM Activation invalid"
        return 3
      elif echo "$line" | grep -q "xyz.openbmc_project.Software.Activation.Activations.NotReady"; then
        log "PLDM Activation not ready"
        return 4
      elif echo "$line" | grep -q "xyz.openbmc_project.Software.Activation.Activations.Active"; then
        log "PLDM Activation completed successfully"
        return 0
      fi
    fi
  done < <(timeout 1600s dbus-monitor --system \
        "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='$obj'")

  return 5
}

# ---- main -------------------------------------------------------------------
section "PLDM UPDATE"
[ -f "${LOCAL_PATH}" ] || {
  log "ERROR: image not found: ${LOCAL_PATH}"
  redfish_log_abort "PLDM image not found"
  update_percentage "$UPDATE_PERCENT_FAIL"
  exit 2
}

log "IMAGE_DIR=${IMAGE_DIR} IMAGE_PATH=${IMAGE_PATH} TARGETS=${TARGETS:-<none>}"

set_fw_meta_pldm
ensure_prereqs

# Stage event to match original flow
redfish_log_fw_evt staged || true
update_percentage "$UPDATE_PERCENT_PRESTAGE_VERIFY_START"

obj_path="$(_wait_for_activation_object || true)"
if [ -z "$obj_path" ]; then
  log "Timeout expired while waiting for InterfacesAdded signal with Activation interface."
  redfish_log_abort "PLDM Update - Activation interface not found"
  update_percentage "$UPDATE_PERCENT_FAIL"
  exit 1
fi

log "Found object with Activation interface: $obj_path"

# Request activation
if ! _request_activation_active "$obj_path"; then
  log "Error: Failed to set RequestedActivation to 'Active'"
  redfish_log_abort "PLDM Update - RequestedActivation failed"
  update_percentage "$UPDATE_PERCENT_FAIL"
  exit 1
fi

# Monitor to completion
rc=0
if ! _monitor_activation_to_completion "$obj_path"; then
  rc=$?
  case "$rc" in
    2) redfish_log_abort "PLDM Update - Activation failed" ;;
    3) redfish_log_abort "PLDM Update - Activation invalid" ;;
    4) redfish_log_abort "PLDM Update - Activation not ready" ;;
    5) redfish_log_abort "PLDM Update - Activation progress monitoring failed" ;;
    *) redfish_log_abort "PLDM Update - Unknown error" ;;
  esac
  update_percentage "$UPDATE_PERCENT_FAIL"
  exit 1
fi

# Done
redfish_log_fw_evt success || true
update_percentage "$UPDATE_PERCENT_SUCCESS"
log "PLDM update stage complete."
exit 0