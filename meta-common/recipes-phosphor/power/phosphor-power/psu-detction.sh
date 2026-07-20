#!/usr/bin/env bash

set -u

JSON_DEFAULT="/usr/share/phosphor-power/psu.json"
JSON_FILE="${1:-$JSON_DEFAULT}"

if [[ ! -f "$JSON_FILE" ]]; then
    echo "JSON file not found: $JSON_FILE" >&2
    exit 1
fi

if ! command -v i2cget >/dev/null 2>&1; then
    echo "i2cget command not found" >&2
    exit 1
fi

to_hex() {
    printf "0x%02x" "$1"
}

declare -a PSU_NAME=()
declare -a PSU_BUS=()
declare -a PSU_EEPROM=()
declare -a PSU_ADDRESS=()

load_probe_entries() {
    local name bus eeprom address
    name=""
    bus=""
    eeprom=""
    address=""

    while IFS= read -r line; do
        case "$line" in
            *'"Inventory"'*)
                name=""
                bus=""
                eeprom=""
                address=""
                ;;
            *'"Name"'*)
                name=$(printf "%s" "$line" | sed -n 's/.*"Name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
                ;;
            *'"Bus"'*)
                bus=$(printf "%s" "$line" | sed -n 's/.*"Bus"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p')
                ;;
            *'"EEPROM"'*)
                eeprom=$(printf "%s" "$line" | sed -n 's/.*"EEPROM"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p')
                ;;
            *'"Address"'*)
                address=$(printf "%s" "$line" | sed -n 's/.*"Address"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p')
                ;;
            *'},'|*'}')
                if [[ -n "$bus" && -n "$eeprom" && -n "$address" ]]; then
                    PSU_NAME+=("${name:-NA}")
                    PSU_BUS+=("$bus")
                    PSU_EEPROM+=("$eeprom")
                    PSU_ADDRESS+=("$address")
                    name=""
                    bus=""
                    eeprom=""
                    address=""
                fi
                ;;
        esac
    done < "$JSON_FILE"
}

ensure_sysfs_device() {
    local bus="$1"
    local addr_dec="$2"
    local addr_hex dev_id dev_path sysfs_node

    addr_hex="$(to_hex "$addr_dec")"
    dev_id="$(printf "%04x" "$addr_dec")"
    dev_path="/sys/bus/i2c/devices/${bus}-${dev_id}"
    sysfs_node="/sys/bus/i2c/devices/i2c-${bus}/new_device"

    if [[ -d "$dev_path" ]]; then
        echo "Sysfs already present: $dev_path"
        return 0
    fi

    if [[ ! -w "$sysfs_node" ]]; then
        echo "Cannot write sysfs node: $sysfs_node" >&2
        return 1
    fi

    echo "Creating sysfs node: pmbus $addr_hex > $sysfs_node"
    if echo "pmbus $addr_hex" > "$sysfs_node"; then
        echo "Created sysfs node for addr=$addr_hex on bus=$bus"
        return 0
    fi

    if [[ -d "$dev_path" ]]; then
        echo "Sysfs appeared during create: $dev_path"
        return 0
    fi

    echo "Failed to create sysfs node for addr=$addr_hex on bus=$bus" >&2
    return 1
}

probe_entry() {
    local idx="$1"
    local name bus eeprom addr eeprom_hex

    name="${PSU_NAME[$idx]}"
    bus="${PSU_BUS[$idx]}"
    eeprom="${PSU_EEPROM[$idx]}"
    addr="${PSU_ADDRESS[$idx]}"
    eeprom_hex="$(to_hex "$eeprom")"

    if i2cget -y "$bus" "$eeprom_hex" 0x00 >/dev/null 2>&1; then
        ensure_sysfs_device "$bus" "$addr"
        return $?
    fi

    echo "Probe failed for PSU[$idx] $name"
    return 1
}

load_probe_entries

if [[ ${#PSU_BUS[@]} -eq 0 ]]; then
    echo "No valid probe entries found in JSON (need Bus, EEPROM, Address)" >&2
    exit 1
fi

declare -a failed=()
for i in "${!PSU_BUS[@]}"; do
    if ! probe_entry "$i"; then
        failed+=("$i")
    fi
done

if [[ ${#failed[@]} -eq 0 ]]; then
    :
else
    echo "Failed PSUs on first pass: ${failed[*]}"
    echo "Starting background retry every 5 seconds for missing PSUs."
    (
        pending=("${failed[@]}")
        while [[ ${#pending[@]} -gt 0 ]]; do
            sleep 5
            next_failed=()
            for idx in "${pending[@]}"; do
                if probe_entry "$idx"; then
                    echo "Background retry: PSU[$idx] ${PSU_NAME[$idx]} recovered and sysfs created."
                else
                    next_failed+=("$idx")
                fi
            done
            pending=("${next_failed[@]}")
        done
        echo "Background retry: all missing PSUs recovered."
    ) &
    disown $!
    echo "Background retry PID=$! started. Service will continue starting now."
fi

exit 0
