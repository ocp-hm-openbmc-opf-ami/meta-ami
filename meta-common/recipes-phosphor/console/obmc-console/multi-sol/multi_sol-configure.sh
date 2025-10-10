#!/bin/sh

ROUTER=$(echo /sys/bus/platform/drivers/aspeed-uart-routing/*.uart-routing)
[ -L "$ROUTER" ] || exit 2

route() {
    echo -n "$1" > "$ROUTER/$2"
    echo -n "$2" > "$ROUTER/$1"
}

setup_routing() {
    route io0 uart0
    route io1 uart1
    route io2 uart2
    route io8 uart8
    route io9 uart9
    route uart0 io0
    route uart1 io1
    route uart2 io2
    route uart8 io8
    route uart9 io9
}

$1
