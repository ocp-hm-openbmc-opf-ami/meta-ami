#!/bin/sh

ROUTER=$(echo /sys/bus/platform/drivers/aspeed-uart-routing/*.uart-routing)
[ -L "$ROUTER" ] || exit 2

route() {
    echo -n "$1" > "$ROUTER/$2"
    echo -n "$2" > "$ROUTER/$1"
}

setup_routing() {
    echo "Enabling UART routing"

    route uart1 uart3
    route uart3 io1
}

setup() {
    hostserialcfg=$(fw_printenv hostserialcfg 2> /dev/null)
    hostserialcfg=${hostserialcfg##*=}

    if [ "$hostserialcfg" = 1 ]
    then
        baud=921600
    else
        baud=115200
    fi

    echo "Configuring host UART for $baud baud"

    CONSOLE_CONF=/etc/obmc-console/server.ttyS2.conf
    cat > $CONSOLE_CONF <<-EOF
	# AMI Autogenerated by $0
	baud = $baud
	local-tty = ttyS3
	local-tty-baud = $baud
	console-id = default
	logfile= /var/log/obmc-console.log
	logsize = 256k
	EOF
}

teardown() {
    echo "Disabling UART routing"
    route uart1 io1
    route uart3 io3
    route uart3 io4
}

$1
