#!/bin/sh
# flash-bios.sh — Program BIOS/IFWI (PNOR) using flashcp (aligned with flash-bmc-intel.sh/common.sh style)
# Usage: flash-bios.sh IMAGE_DIR IMAGE_PATH TARGET
#
# Positional:
#   IMAGE_DIR  : directory that contains the image + manifest (used if IMAGE_PATH is relative/missing)
#   IMAGE_PATH : absolute path OR filename under IMAGE_DIR
#   TARGET     : logical target/basename (not used for D-Bus paths here; kept for logs/consistency)
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

# ---- Config -----------------------------------------------------------------
: "${preserve_bios:=/tmp/preserveBIOS.json}"

# ---- fail-safe trap ----------------------------------------------------------
trap '
  rc=$?
  if [ $rc -ne 0 ]; then
    log "ERROR: BIOS flash aborted (rc=$rc)"
    redfish_log_abort "BIOS flash aborted"
    update_percentage "$UPDATE_PERCENT_FAIL"
  fi
  wait_for_log_sync
  exit $rc
' ERR INT HUP

# ---- helpers -----------------------------------------------------------------
pre_bios_sanity() {
  command -v flashcp >/dev/null 2>&1 || {
    log "ERROR: flashcp not found in PATH"
    redfish_log_abort "flashcp missing"
    update_percentage "$UPDATE_PERCENT_FAIL"
    exit 127
  }
}

# Get ApplyOptions.ClearConfig (boolean) from /xyz/openbmc_project/software
get_clearconfig_flag() {
  local iface="xyz.openbmc_project.Software.ApplyOptions" prop="ClearConfig"
  dbus_get_property_by_mapper \
    "/xyz/openbmc_project/software" "$iface" "$prop" 2>/dev/null \
    | awk '{print $2}'
}

# Locate PNOR mtd partition name (e.g., mtd4)
find_pnor_mtd() {
  awk '{print $1 $4}' /proc/mtd 2>/dev/null \
    | awk -F: '$2=="\"pnor\"" {print $1; exit}'
}

check_preserve_bios_config() {
    # honor ApplyOptions.ClearConfig; if true -> do not preserve
    value="$(get_clearconfig_flag || true)"
    local mtdPart
    mtdPart="$(find_pnor_mtd || true)"

    if [ ! -f "$preserve_bios" ]; then
        log "BIOS Full Flash - Preserve Configuration JSON not present"
        return 0
    fi

    if [ -n "$value" ]; then
        if [ "$value" = "true" ]; then
            log "BIOS Full Flash - Not Preserving the Config (ClearConfig=true)"
        else
            log "BIOS Full Flash - Start Preserve Config"

            json_data="$(cat "$preserve_bios" 2>/dev/null || true)"
            [ -n "$json_data" ] || { log "Preserve JSON empty"; return 0; }

            config_keys="$(echo "$json_data" | grep -o '"[^"]*": {' | awk -F'"' '{print $2}')"

            for key in $config_keys; do
	         block="$(echo "$json_data" | awk -v RS="}" -v key="\"$key\"" 'index($0,key){print $0 RS}')"
                start="$(echo "$block" | grep -o '"start": *"[^"]*"' | awk -F'"' '{print $4}')"
                length="$(echo "$block" | grep -o '"length": *"[^"]*"' | awk -F'"' '{print $4}')"

                if [ -n "$mtdPart" ] && [ -n "$start" ] && [ -n "$length" ]; then
                    dump_file="/tmp/preserve_bios_$key"
                    dump_log="/tmp/preserve_bios_${key}.log"
                    if nanddump -q -s "$start" -l "$length" -f "$dump_file" "/dev/$mtdPart" >"$dump_log" 2>&1; then
                        if [ -s "$dump_file" ]; then
                            log "BIOS $key Configs Preserved successfully"
                        else
                            log "BIOS $key Configs Preserve failed"
                        fi
                    else
                        log "BIOS $key Configs Preserve failed"
                    fi
                else
                    log "BIOS $key Preserve skipped (missing mtd/start/length)"
                fi
            done
        fi
    else
        log "ClearConfig is not available"
    fi
}

restore_bios_configs() {
    value="$(get_clearconfig_flag || true)"

    if [ "$value" = "true" ]; then
        # set clear configs to false
        dbus_set_prop xyz.openbmc_project.Software.BMC.Updater \
            /xyz/openbmc_project/software \
            xyz.openbmc_project.Software.ApplyOptions ClearConfig \
            b false || true
        return 0
    fi

    if [ ! -f "$preserve_bios" ]; then
        log "BIOS Full Flash - Preserve Configuration JSON not present"
        return 0
    fi

    local mtdPart
    mtdPart="$(find_pnor_mtd || true)"

    json_data="$(cat "$preserve_bios" 2>/dev/null || true)"
    [ -n "$json_data" ] || { log "Preserve JSON empty"; return 0; }

    config_keys="$(echo "$json_data" | grep -o '"[^"]*": {' | awk -F'"' '{print $2}')"

    for key in $config_keys; do
	 block="$(echo "$json_data" | awk -v RS="}" -v key="\"$key\"" 'index($0,key){print $0 RS}')"
        start="$(echo "$block" | grep -o '"start": *"[^"]*"' | awk -F'"' '{print $4}')"

        if [ -n "$mtdPart" ] && [ -n "$start" ] && [ -s "/tmp/preserve_bios_$key" ]; then
            nandwrite -s "$start" "/dev/${mtdPart}" "/tmp/preserve_bios_$key" 2>&1
            if [ $? -eq 0 ]; then
                log "BIOS Full Flash - restore $key Configs preserved successfully"
            else
                log "BIOS Full Flash - restore $key Configs preserved failed"
            fi
        else
            log "BIOS Full Flash - restore $key skipped (missing mtd/start/file)"
        fi
    done

    for key in $config_keys; do
        rm -f "/tmp/preserve_bios_$key" 2>/dev/null || true
    done
}

# Extract FWTYPE/FWVER; IFWI image may not contain version; default to NA
set_fw_meta_bios() {
  FWTYPE="BIOS"
  # Try manifest, else NA
  dir="$(dirname "${LOCAL_PATH}")"
  FWVER=""
  if [ -f "$dir/MANIFEST" ]; then
    FWVER="$(awk -F= '/^version=/ {print $2}' "$dir/MANIFEST" 2>/dev/null || true)"
  fi
  [ -n "$FWVER" ] || FWVER="NA"
  export FWTYPE FWVER
}

# ---- main -------------------------------------------------------------------
section "BIOS FLASH"
[ -f "${LOCAL_PATH}" ] || {
  log "ERROR: image not found: ${LOCAL_PATH}"
  redfish_log_abort "BIOS image not found"
  update_percentage "$UPDATE_PERCENT_FAIL"
  exit 2
}

log "TARGET=${TARGET} IMAGE_DIR=${IMAGE_DIR} IMAGE_PATH=${IMAGE_PATH}"

set_fw_meta_bios
pre_bios_sanity

update_percentage "$UPDATE_PERCENT_PRESTAGE_VERIFY_START"
update_percentage "$UPDATE_PERCENT_PRESTAGE_VERIFY_COMPLETE"
update_percentage "$UPDATE_PERCENT_FLASH_OR_STAGE_START"

mtdPart="$(find_pnor_mtd || true)"
log "mtdPart=$mtdPart"
if [ -z "$mtdPart" ]; then
    log "IFWI Full Flash - host mtd partition not found"
    redfish_log_abort "IFWI Full Flash - Image update failed"
    update_percentage "$UPDATE_PERCENT_FAIL"
    exit 1
fi

# Flash: writing to BIOS SPI device
check_preserve_bios_config
log "IFWI Full Flash - Starting the SPI write. It will take ~5 minutes...."

if flashcp "$LOCAL_PATH" "/dev/$mtdPart"; then
    update_percentage "$UPDATE_PERCENT_FLASH_OR_STAGE_COMPLETE"
    log "IFWI Full Flash - Image update successful"
    restore_bios_configs
    redfish_log_fw_evt success
    update_percentage "$UPDATE_PERCENT_SUCCESS"
    exit 0
else
    rc=$?
    log "IFWI Full Flash - Image update failed (rc=$rc)"
    redfish_log_abort "IFWI Full Flash - Image update failed"
    update_percentage "$UPDATE_PERCENT_FAIL"
    exit 1
fi
