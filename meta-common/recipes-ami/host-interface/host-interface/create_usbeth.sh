#! /bin/sh

set -x # Debug mode

eth_conf_directory="/sys/kernel/config/usb_gadget/eth"
dev_name=""

detect_platform() {
    # AST2600
    if [ -e "/sys/bus/platform/devices/1e6a0000.usb-vhub" ]; then
        dev_name="1e6a0000"
    fi

    # AST27xx
    #Todo: To support dual node, the detection case for 2700/2750 needs to be refined.
    if [ -e "/sys/bus/platform/devices/12011000.usb-vhub" ]; then
        dev_name="12011000"
    fi
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
    mkdir functions/ecm.usb0
    echo $dev_mac > functions/ecm.usb0/dev_addr
    echo $host_mac > functions/ecm.usb0/host_addr
    mkdir configs/c.2
    echo 0 > configs/c.2/MaxPower
    echo 0xC0 > configs/c.2/bmAttributes
    mkdir configs/c.2/strings/0x409

    # Rename
    echo hostusb%d > functions/ecm.usb0/ifname

    # Create configuration for rndis
    mkdir functions/rndis.usb0
    echo $dev_mac > functions/rndis.usb0/dev_addr
    echo $host_mac > functions/rndis.usb0/host_addr
    echo RNDIS > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
    echo 5162001 > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id
    mkdir configs/c.1
    echo 0 > configs/c.1/MaxPower
    echo 0xC0 > configs/c.1/bmAttributes
    mkdir configs/c.1/strings/0x409
    
    # Link ECM and RNDIS functions to their respective configurations
    ln -s functions/ecm.usb0 configs/c.2/
    ln -s functions/rndis.usb0 configs/c.1/
    ln -s configs/c.1 os_desc/c.1
}

connect_eth() {
    if ! grep -q "${dev_name}:p" UDC; then
        i=0
        num_ports=5
        base_usb_dir="/sys/bus/platform/devices/${dev_name}/${dev_name}:p"
        while [ "${i}" -lt "${num_ports}" ]; do
            port=$(("${i}" + 1))
            i="${port}"
            if [ ! -e "${base_usb_dir}${port}/gadget/suspended" ]; then
                break
            fi
        done
        echo "${dev_name}:p${port}" > UDC
    fi
}


if [ ! -e "${eth_conf_directory}" ]; then
    create_eth
else
    cd "${eth_conf_directory}" || exit 1
fi

if [ "$1" = "connect" ]; then
    detect_platform
    connect_eth
    ## Assigning MAC address
    USB0_MAC=$(dmesg | grep "hostusb0: MAC" | cut -d ' ' -f 7)
    ifconfig hostusb0 down
    ifconfig hostusb0 hw ether $USB0_MAC
    ifconfig hostusb0 169.254.0.17 netmask 255.255.0.0
    ifconfig hostusb0 up

else
    echo >&2 "Invalid option: $1. Use 'connect'."
    exit 1
fi
