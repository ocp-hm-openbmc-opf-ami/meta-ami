#!/bin/sh

GADGET_BASE=/sys/kernel/config/usb_gadget
USB_VHUB=/sys/bus/platform/devices/1e6a0000.usb-vhub
NAME=uartusb

free_port() {
    local p
    for p in /sys/class/udc/*; do
        p=$(basename $p)
        if ! test -e $USB_VHUB/$p/gadget/suspended; then
            echo $p
            return
        fi
    done
    echo "All ports taken" >&2
    exit 1
}


usb_uart_create()
{
    if [ -d $GADGET_BASE/$NAME ]; then
        echo "device $NAME already exists" >&2
        return 1
    fi
    mkdir $GADGET_BASE/$NAME
    cd $GADGET_BASE/$NAME

    echo 0x1d6b > idVendor  # Linux Foundation
    echo 0x0105 > idProduct # FunctionFS Gadget
    mkdir strings/0x409
    local serial="OBMCUART001"
    echo $serial > strings/0x409/serialnumber
    echo OpenBMC > strings/0x409/manufacturer
    echo "OpenBMC Uart" > strings/0x409/product

    mkdir configs/c.1
    mkdir functions/acm.$NAME
    mkdir configs/c.1/strings/0x409

    echo "Config-1" > configs/c.1/strings/0x409/configuration
    echo 120 > configs/c.1/MaxPower
    ln -s functions/acm.$NAME configs/c.1
    echo $(free_port) > UDC
}

if test "$1" = stop; then
    rm -f $GADGET_BASE/$NAME/configs/c.1/acm.$NAME
    rmdir $GADGET_BASE/$NAME/configs/c.1/strings/0x409
    rmdir $GADGET_BASE/$NAME/configs/c.1
    rmdir $GADGET_BASE/$NAME/functions/acm.$NAME
    rmdir $GADGET_BASE/$NAME/strings/0x409
    rmdir $GADGET_BASE/$NAME
else
    usb_uart_create
fi
