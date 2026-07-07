#!/bin/bash
# MCTP I3C Rescan Library
# Can be sourced or executed directly

# Function to parse I3C devices from mctp_ext_options.json MCTPI3CTarget entries
parse_i3c_busowner_devices() {
	local config_file="${MCTP_CONF:-/usr/share/mctp/mctp_ext_options.json}"

	echo "DEBUG: Parsing I3C devices from: $config_file" >&2

	if [ ! -f "$config_file" ]; then
		echo "DEBUG: Config file not found: $config_file" >&2
		return
	fi

	# Extract MCTPI3CTarget entries and output: name|bus_num|pid_mask|device_pid|role|is_secondary|is_i3c_target
	python3 -c "
import json, sys
with open('$config_file') as f:
    data = json.load(f)
for item in data:
    for exp in item.get('Exposes', []):
        if exp.get('Type') != 'MCTPI3CTarget':
            continue
        name = exp.get('Name', '')
        bus = exp.get('Bus', '')
        pid_mask = exp.get('PidMask', '')
        if pid_mask:
            pid_mask = pid_mask.replace('0x', '')
        addr = exp.get('Address', [])
        device_pid = ''.join(format(b, '02x') for b in addr) if addr else ''
        role = exp.get('Role', '')
        is_secondary = str(exp.get('SecondaryBusOwner', False)).lower()
        is_i3c_target = str(exp.get('I3CTarget', False)).lower()
        print(f'{name}|{bus}|{pid_mask}|{device_pid}|{role}|{is_secondary}|{is_i3c_target}')
" 2>/dev/null
}

# Function to setup I3C busowner device
setup_i3c_busowner_device() {
	local bus_num="$1"
	local is_i3c_target="${2:-false}"
	local IFNAME EID

	if [ "$is_i3c_target" = "false" ]; then
		IFNAME="mctpi3c-target${bus_num}"
		EID="0x0b"
	else
		IFNAME="mctpi3c$((bus_num-2))"
		EID="0x0a"
	fi
	echo "Configuring bus $bus_num => IFNAME=$IFNAME, EID=$EID (I3c_target: $is_i3c_target)"

	echo "Setting up I3C device on bus $bus_num (interface: $IFNAME)"

	# Setup MCTP link
	if mctp link set "$IFNAME" net "$MCTP_I3C_NET" up 2>/dev/null; then
		echo "  Link setup successful: $IFNAME"
	else
		echo "  Warning: Failed to setup link for $IFNAME"
	fi

	# Add address
	if mctp addr add "$EID" dev "$IFNAME" 2>/dev/null; then
		echo "  Address setup successful: $EID on $IFNAME"
	else
		echo "  Warning: Failed to add address $EID to $IFNAME"
	fi
}

mctp_i3c_rescan() {

# --- Parameters ---
# $1 = bus_num              (mandatory)
# $2 = pid_masks            (pipe-delimited list, e.g. "0F|100F", one per device)
# $3 = device_pids          (pipe-delimited list, e.g. "|020a0000000b", one per device)
# $4 = roles                (pipe-delimited list, e.g. "busowner|busowner", one per device)
# $5 = is_secondaries       (pipe-delimited list, e.g. "false|true", one per device)
# $6 = is_i3c_targets       (pipe-delimited list, e.g. "true|false", one per device)
#                            true  => interface mctpi3c<bus>  (controller)
#                            false => interface mctpi3c-target<bus>  (target)
# For each index, either pid_mask or device_pid must be non-empty.
local bus_num="$1"
local pid_masks_arg="$2"
local device_pids_arg="$3"
local roles_arg="$4"
local is_secondaries_arg="$5"
local is_i3c_targets_arg="$6"

# Validate mandatory bus_num
if [[ -z "$bus_num" ]]; then
    echo "[Error] bus_num is mandatory but was not provided"
    return 1
fi

# Validate that at least one list was provided
if [[ -z "$pid_masks_arg" ]] && [[ -z "$device_pids_arg" ]]; then
    echo "[Error] Either pid_masks or device_pids must be provided"
    return 1
fi

# Split pipe-delimited lists into arrays
IFS='|' read -ra pid_masks_list      <<< "$pid_masks_arg"
IFS='|' read -ra device_pids_list    <<< "$device_pids_arg"
IFS='|' read -ra roles_list          <<< "$roles_arg"
IFS='|' read -ra is_secondaries_list <<< "$is_secondaries_arg"
IFS='|' read -ra is_i3c_targets_list <<< "$is_i3c_targets_arg"

# Determine how many devices are on this bus (use whichever list is longer)
local num_devices=${#pid_masks_list[@]}
if [[ ${#device_pids_list[@]} -gt $num_devices ]]; then
    num_devices=${#device_pids_list[@]}
fi

echo "[Info] Bus $bus_num: scanning $num_devices device(s)"

# --- Configuration ---
local BASE_PATH="/sys/bus/platform/devices"
MCTP_PLATFORM="${MCTP_PLATFORM:=aspeed-2600}"
MCTP_I3C_NET ="${MCTP_I3C_NET:-8}"  # Default to network 8 for I3C devices

# Read settings from mctp_ext_options.json if available
local MCTP_EXT_CONF="${MCTP_EXT_CONF:-/usr/share/mctp/mctp_ext_options.json}"
if [ -f "$MCTP_EXT_CONF" ]; then
	eval "$(python3 -c "
import json
with open('$MCTP_EXT_CONF') as f:
    data = json.load(f)
for item in data:
    for exp in item.get('Exposes', []):
        if exp.get('Type') != 'MCTPI3CConfiguration':
            continue
        soc = exp.get('Soc', '')
        if soc:
            print(f'MCTP_PLATFORM={soc}')
        net = exp.get('Net', '')
        if net:
            print(f'MCTP_I3C_NET={net}')
" 2>/dev/null)"
fi

# Constants
local MASK=0xFF0F
local MAX_RETRIES=20
local RETRY_DELAY=1

local DBUS_DEST="au.com.codeconstruct.MCTP1"
local DBUS_IFACE="au.com.codeconstruct.MCTP.Interface1"
# DBUS_OBJ is derived per-device from is_i3c_targets_list and bus_num

local BUS_PATH
local i3c_dir
local i3c_name
local sub_dir
local sub_name
local expected_suffix
local pid_file
local rescan_file
local attempt
local success=false
# Per-device detection flags (index-aligned with pid_masks_list / device_pids_list)
declare -a device_detected
for (( d=0; d<num_devices; d++ )); do device_detected[$d]=false; done
# Formatted PID strings for DiscoveryNotify, one per device
declare -a formatted_ids

echo "[Mode] Multi-device scan on bus $bus_num ($num_devices device(s))"

# Check if MCTP service exists
if ! busctl list | grep -q "$DBUS_DEST"; then
    echo "Error: D-Bus service $DBUS_DEST not found"
    return 1
fi

if [[ "$MCTP_PLATFORM" = "aspeed-2700" ]]; then
    # Map BUS number to device path
    case "$bus_num" in
        0) BUS_PATH="14c20000.i3c0" ;;
        1) BUS_PATH="14c21000.i3c1" ;;
        2) BUS_PATH="14c22000.i3c2" ;;
        3) BUS_PATH="14c23000.i3c3" ;;
        4) BUS_PATH="14c24000.i3c4" ;;
        5) BUS_PATH="14c25000.i3c5" ;;
        6) BUS_PATH="14c26000.i3c6" ;;
        *)
            echo "[Error] Invalid bus_num: $bus_num"
            return 1
            ;;
    esac
else
    case "$bus_num" in
        0) BUS_PATH="1e7a2000.i3c0" ;;
        1) BUS_PATH="1e7a3000.i3c1" ;;
        2) BUS_PATH="1e7a4000.i3c2" ;;
        3) BUS_PATH="1e7a5000.i3c3" ;;
        4) BUS_PATH="1e7a6000.i3c4" ;;
        5) BUS_PATH="1e7a7000.i3c5" ;;
        *)
            echo "[Error] Invalid bus_num: $bus_num"
            return 1
            ;;
    esac
fi

format_mctp_id() {
    local hex=$1
    # Remove 0x prefix if it exists
    hex="${hex#0x}"
    # Pad to 8 characters if necessary (for 4 bytes)
    printf -v hex "%012s" "$hex"
    hex="${hex// /0}"
   
    # Extract bytes and format
    echo "array:byte:0x${hex:0:2},0x${hex:2:2},0x${hex:4:2},0x${hex:6:2},0x${hex:8:2},0x${hex:10:2}"
}

# Enhanced device status check with retries
# This functions checks if device is active with multiple attempts
check_device_status() {
    local status_file=$1
    local max_attempts=3
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if [ -f "$status_file" ] && cat "$status_file" > /dev/null 2>&1; then
            return 0  # Device is active
        fi

        if [ $attempt -lt $((max_attempts - 1)) ]; then
            echo "[Debug] Status check failed, retrying..."
        fi
        attempt=$((attempt + 1))
    done

    return 1  # Device status check failed
}

# Send D-Bus DiscoveryNotify with 3 retries
# $1 = device_id   $2 = device_name   $3 = interface name (e.g. mctpi3c0 or mctpi3c-target0)
send_discovery_notify() {
    local device_id="$1"
    local device_name="$2"
    local dbus_obj="/au/com/codeconstruct/mctp1/interfaces/$3"

    for attempt in 1 2 3; do
        if dbus-send --system --print-reply --dest="$DBUS_DEST" "$dbus_obj" "$DBUS_IFACE".DiscoveryNotify "$device_id" 2>/dev/null; then
            echo "[Success] DiscoveryNotify sent for $device_name (interface: $3)"
            return 0
        fi
    done

    echo "[Error] Failed to send DiscoveryNotify for $device_name after 3 attempts"
    return 1
}

echo "=== Scanning BUS: $BUS_PATH ==="

# Verify the i3c bus path exists and is accessible
if [ ! -d "$BASE_PATH/$BUS_PATH" ]; then
    echo "[Error] i3c bus path not found: $BASE_PATH/$BUS_PATH"
    echo "[Debug] Available devices: $(ls -1 "$BASE_PATH" 2>/dev/null | grep -i i3c | head -10)"
    return 1
fi

echo "[Info] i3c bus path verified: $BASE_PATH/$BUS_PATH"

# Find the first i3c controller and get rescan file
local rescan_file=""
for i3c_dir in "$BASE_PATH/$BUS_PATH"/i3c-*; do
    [ -e "$i3c_dir" ] || continue
    rescan_file="$i3c_dir/rescan"
    break
done

if [ ! -f "$rescan_file" ]; then
    echo "[Error] No rescan file found. Aborting."
    return 1
fi

# Retry loop - rescan once per attempt, then check all devices
attempt=0
while [ $attempt -lt $MAX_RETRIES ] && [ "$success" = false ]; do
    echo "=== Rescan Attempt $((attempt + 1)) ==="

    # Rescan the bus once per attempt
    #echo "  [Rescan] Triggering bus rescan..."
    if echo 1 > "$rescan_file" 2>/dev/null; then
        echo "  [Rescan] Successfully wrote '1' to $rescan_file to trigger rescan"
    else
        echo "  [Error] Failed to write to rescan file: $rescan_file"
        attempt=$((attempt + 1))
        continue
    fi
    sleep $RETRY_DELAY

    # Reset detection flags for this attempt
    primary_device_detected=false

    # Check all i3c controllers and their devices
    for i3c_dir in "$BASE_PATH/$BUS_PATH"/i3c-*; do
        [ -e "$i3c_dir" ] || continue
        i3c_name=$(basename "$i3c_dir")

        echo "=== Controller: $i3c_name ==="

        # Look for device subfolders like 1-xxxxxxx
        for sub_dir in "$i3c_dir"/*; do
            [ -d "$sub_dir" ] || continue
            sub_name=$(basename "$sub_dir")

            # DEVICE FOLDER VALIDATION:
            # I3C device folders follow pattern: 1-<HEX_PID>
            # Example: 1-48b4590f represents device with PID 0x48b4590f
            if [[ "$sub_name" =~ ^1-([0-9a-fA-F]+)$ ]]; then
                expected_suffix="${BASH_REMATCH[1]}"  # Extract hex PID from folder name
                pid_file="$sub_dir/pid"               # Path to PID file in device folder
                status_file="$sub_dir/status"         # Path to status file in device folder

                echo "status file path: $status_file"
                echo "=== Checking Device: $sub_name ==="

                if [ -f "$pid_file" ] && [ -f "$status_file" ]; then
                    # READ PID FROM SYSFS:
                    # PID file contains hex value (with or without 0x prefix)
                    # Remove all whitespace (newlines, spaces, tabs)
                    raw_hex=$(tr -d '[:space:]' < "$pid_file" 2>/dev/null)

                    if [ -n "$raw_hex" ]; then
                        # PID VALIDATION:
                        # Verify PID file content matches the folder name suffix
                        # This ensures sysfs consistency (case-insensitive comparison)
                        if [[ "${raw_hex,,}" == "${expected_suffix,,}" ]]; then

                            # PID FORMAT NORMALIZATION:
                            # Ensure hex value has proper "0x" prefix for arithmetic
                            if [[ "$raw_hex" =~ ^0x ]]; then
                                clean_hex="$raw_hex"      # Already has 0x prefix
                            else
                                clean_hex="0x$raw_hex"     # Add 0x prefix
                            fi

                            # PID MASK COMPARISON:
                            val_int=$((clean_hex))                    # Convert to decimal

                            # DEVICE TYPE IDENTIFICATION:
                            # For each device configured on this bus, check if this sysfs entry matches
                            for (( d=0; d<num_devices; d++ )); do
                                [ "${device_detected[$d]}" = true ] && continue  # already found

                                local pmask_entry="${pid_masks_list[$d]:-}"
                                local pid_entry="${device_pids_list[$d]:-}"
                                local pid_match=false

                                if [[ -n "$pmask_entry" ]]; then
                                    # PID mask mode: apply mask and compare
                                    local pmask_int=$(( 0x${pmask_entry#0x} ))
                                    local masked_pid=$(( val_int & MASK ))
                                    echo " Device[$d] Hex: $raw_hex | Masked: $(printf '0x%x' $masked_pid) | Expected mask: $(printf '0x%x' $pmask_int)"
                                    [ "$masked_pid" -eq "$pmask_int" ] && pid_match=true
                                elif [[ -n "$pid_entry" ]]; then
                                    # Direct PID mode: exact match
                                    local pid_int=$(( 0x${pid_entry#0x} ))
                                    echo " Device[$d] Hex: $raw_hex | Direct PID: $(printf '0x%x' $pid_int)"
                                    [ "$val_int" -eq "$pid_int" ] && pid_match=true
                                fi

                                if [ "$pid_match" = true ]; then
                                    echo "[Success] Device[$d] matched. Checking status..."
                                    if check_device_status "$status_file"; then
                                        echo "[Success] Device[$d] status check passed. Device is active."
                                        device_detected[$d]=true
                                        formatted_ids[$d]=$(format_mctp_id "$raw_hex")
                                    else
                                        echo "[Warning] Device[$d] status check failed. Will retry."
                                    fi
                                fi
                            done
                        else
                            echo "[Warning] PID file content ($raw_hex) doesn't match directory suffix ($expected_suffix)"
                        fi
                    else
                        echo "[Warning] Empty or invalid PID file"
                    fi
                else
                    echo "[Warning] PID file not found"
                fi
            fi
        done
    done

    # Check if all devices on this bus were detected in this attempt
    local all_found=true
    for (( d=0; d<num_devices; d++ )); do
        if [ "${device_detected[$d]}" = false ]; then
            all_found=false
            echo "[Status] Attempt $((attempt + 1)): Device[$d] not yet detected"
        fi
    done

    if [ "$all_found" = true ]; then
        echo "[Success] All $num_devices device(s) detected on bus $bus_num in attempt $((attempt + 1))"
        success=true
        break
    fi

    attempt=$((attempt + 1))
done

# Final result
if [ "$success" = true ]; then
    # Create marker file to indicate successful rescan
    #touch /tmp/.mctp_i3c_rescan_done

    echo "=== SCAN COMPLETE: All $num_devices device(s) detected on bus $bus_num ==="

    # Send DiscoveryNotify for primary bus owners first (is_secondary=false)
    for (( d=0; d<num_devices; d++ )); do
        [[ -n "${formatted_ids[$d]}" ]] || continue
        [[ "${is_secondaries_list[$d]:-false}" == "true" ]] && continue
        [[ "${roles_list[$d]:-}" == "bus-owner" ]] || { echo "[Info] Skipping DiscoveryNotify for device[$d] (role=${roles_list[$d]:-unset}, not bus-owner)"; continue; }
        local iface
        if [[ "${is_i3c_targets_list[$d]:-true}" == "true" ]]; then
            iface="mctpi3c$((bus_num-2))"
        else
            iface="mctpi3c-target${bus_num}"
        fi
        echo "[Debug] Sending DiscoveryNotify: ID=${formatted_ids[$d]}, Name=device[$d] (primary), Interface=$iface"
        send_discovery_notify "${formatted_ids[$d]}" "device[$d] (primary) on bus $bus_num" "$iface" || return 1
    done

    # Send DiscoveryNotify for secondary bus owners after 20s delay
    local has_secondary=false
    for (( d=0; d<num_devices; d++ )); do
        [[ "${is_secondaries_list[$d]:-false}" == "true" ]] && [[ -n "${formatted_ids[$d]}" ]] && [[ "${roles_list[$d]:-}" == "bus-owner" ]] && has_secondary=true && break
    done

    if [ "$has_secondary" = true ]; then
        echo "[Info] Waiting 20 seconds before notifying secondary bus owners..."
        sleep 20
        for (( d=0; d<num_devices; d++ )); do
            [[ -n "${formatted_ids[$d]}" ]] || continue
            [[ "${is_secondaries_list[$d]:-false}" != "true" ]] && continue
            [[ "${roles_list[$d]:-}" == "bus-owner" ]] || { echo "[Info] Skipping DiscoveryNotify for device[$d] (role=${roles_list[$d]:-unset}, not bus-owner)"; continue; }
            local iface
            if [[ "${is_i3c_targets_list[$d]:-true}" == "true" ]]; then
                iface="mctpi3c$((bus_num-2))"
            else
                iface="mctpi3c-target${bus_num}"
            fi
            send_discovery_notify "${formatted_ids[$d]}" "device[$d] (secondary) on bus $bus_num" "$iface" || return 1
        done
    fi

    return 0
else
    echo "=== SCAN FAILED: Not all devices detected on bus $bus_num after $MAX_RETRIES attempts ==="
    return 2
fi

}

# If script is executed directly (not sourced), run the main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    mctp_i3c_rescan "$@"
fi
