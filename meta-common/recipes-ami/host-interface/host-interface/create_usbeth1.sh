#! /bin/bash

set -euo pipefail
#set -x # Debug mode

eth_conf_directory="/sys/kernel/config/usb_gadget/eth1"
prefix=""
port_count=""
port_start=""

detect_platform() {
    # AST27xx Node 1
    if [ -e "/sys/bus/platform/devices/12021000.usb-vhub" ] || [ -e "/sys/bus/platform/devices/12062000.usb-vhub" ]; then

        if [ -e "/sys/bus/platform/devices/12021000.usb-vhub" ]; then
            prefix="12021000.usb-vhub:p"  # For PCIE-XHCI-USB
        fi

        if [ -e "/sys/bus/platform/devices/12062000.usb-vhub" ]; then
            prefix="12062000.usb-vhub:p"  # For Physical-USB
        fi

        port_count=7
        port_start=1

        return 0
    fi

    return 1
}

generate_random_mac() {
    # Read 6 bytes from /dev/urandom
    mac=$(dd if=/dev/urandom bs=1 count=6 2>/dev/null | hexdump -v -e '/1 "%02x"')

    # Set the locally administered bit and clear the multicast bit
    first_byte=$(printf '%02x' $(( (0x${mac:0:2} & 0xfe) | 0x02 )))
    # Reassemble the MAC address
    mac="${first_byte}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"

    echo "$mac"
}

mac_decrement() {
    local addr="$1"
    IFS=":" read -r -a bytes <<< "$addr"
    
    bytes[5]=$(printf "%02x" $(( (0x${bytes[5]} - 1) & 0xff )))
    
    echo "${bytes[*]}" | tr ' ' ':'
}

is_valid_mac() {
    local addr="$1"
    first_byte=$(( 0x${addr:0:2} ))
    
    if [ $((first_byte & 1)) -eq 0 ] && [ $((first_byte & 2)) -ne 0 ]; then
        return 0
    else
        return 1
    fi
}

generate_and_validate_mac() {
    while :; do
        dev_mac=$(generate_random_mac)
        host_mac=$(mac_decrement "$dev_mac")
        
        if is_valid_mac "$host_mac"; then
            echo "Device MAC: $dev_mac"
            echo "Host MAC: $host_mac"
            break
        fi
    done
}

create_eth() {

    # generate host_mac and dev_mac
    generate_and_validate_mac

    # create gadget
    mkdir "${eth_conf_directory}"
    cd "${eth_conf_directory}" || exit 1

    # Set USB gadget Vendor ID and Product ID
    echo 0x046b > idVendor
    echo 0xFFb0 > idProduct

    # Set USB gadget Class, SubClass, and Protocol
    echo 0x02 > bDeviceClass
    echo 0x00 > bDeviceSubClass
    echo 0x00 > bDeviceProtocol

    # Set device version
    echo 0x0100 > bcdDevice

    # Create strings directory and set serial number, manufacturer, and product name
    mkdir strings/0x409
    echo "American Megatrends Inc" > strings/0x409/manufacturer
    echo "Virtual Ethernet." > strings/0x409/product
    echo "1234567890" > strings/0x409/serialnumber

    # Create interface for ECM and configure it.
    mkdir functions/ecm.ami
    echo "$dev_mac" > functions/ecm.ami/dev_addr
    echo "$host_mac" > functions/ecm.ami/host_addr
    mkdir configs/c.2
    echo 0 > configs/c.2/MaxPower
    echo 0xC0 > configs/c.2/bmAttributes
    mkdir configs/c.2/strings/0x409

    # Rename
    echo hostusb1 > functions/ecm.ami/ifname

    # Create configuration for rndis
    mkdir functions/rndis.ami
    echo "$dev_mac" > functions/rndis.ami/dev_addr
    echo "$host_mac" > functions/rndis.ami/host_addr
    echo RNDIS > functions/rndis.ami/os_desc/interface.rndis/compatible_id
    echo 5162001 > functions/rndis.ami/os_desc/interface.rndis/sub_compatible_id
    mkdir configs/c.1
    echo 0 > configs/c.1/MaxPower
    echo 0xC0 > configs/c.1/bmAttributes
    mkdir configs/c.1/strings/0x409
    
    # Link ECM and RNDIS functions to their respective configurations
    ln -s functions/ecm.ami configs/c.2/
    ln -s functions/rndis.ami configs/c.1/
    ln -s configs/c.1 os_desc/c.1
}

connect_eth() {
    if [[ -f UDC && -n "$(cat UDC)" ]]; then
        return 0
    fi

    local port_index="$port_start"

    while (( port_index < port_start + port_count )); do
        local device="/sys/class/udc/${prefix}${port_index}/device"
        local gadget=""
        
        gadget=$(echo "$device"/gadget* 2>/dev/null | awk -F'/' '{print $NF}' || true)
        if [[ -n "$gadget" ]]; then
            local suspended_file="$device/$gadget/suspended"
            
            if [[ ! -e "$suspended_file" && -f UDC && -z "$(cat UDC)" ]]; then
                echo "${prefix}${port_index}" > UDC
                return 0
            fi
        fi
        
        port_index=$((port_index + 1))
    done

    return 0
}

disconnect_eth() {
    if [[ -f UDC && -n "$(cat UDC)" ]]; then
        echo "" > UDC
    fi
}

if [ ! -e "${eth_conf_directory}" ]; then
    create_eth
else
    cd "${eth_conf_directory}" || { echo >&2 "WARNING: Failed to cd into ${eth_conf_directory}, skipping."; exit 0; }
fi

if [ "$1" = "connect" ]; then
    if ! detect_platform; then
        echo >&2 "WARNING: Unsupported platform, skipping connect."
        exit 0
    fi
    connect_eth
elif [ "$1" = "disconnect" ]; then
    disconnect_eth
else
    echo >&2 "Invalid option: $1. Use 'connect' or 'disconnect'."
    exit 1
fi
