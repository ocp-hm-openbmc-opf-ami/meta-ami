#!/bin/sh

ETHADDR=`fw_printenv | grep "ethaddr" | cut -d"=" -f2`
if [ "$ETHADDR" != "" ] ;then
	ip link set dev eth0 down
	ip link set dev eth0 address $ETHADDR
	ip link set dev eth0 up
fi

ETH1ADDR=`fw_printenv | grep "eth1addr" | cut -d"=" -f2`
if [ "$ETH1ADDR" != "" ] ;then
        ip link set dev eth1 down
        ip link set dev eth1 address $ETH1ADDR
        ip link set dev eth1 up
fi

ETH2ADDR=`fw_printenv | grep "eth2addr" | cut -d"=" -f2`
if [ "$ETH2ADDR" != "" ] ;then
        ip link set dev eth2 down
        ip link set dev eth2 address $ETH2ADDR
        ip link set dev eth2 up
fi

ETH3ADDR=`fw_printenv | grep "eth3addr" | cut -d"=" -f2`
if [ "$ETH3ADDR" != "" ] ;then
        ip link set dev eth3 down
        ip link set dev eth3 address $ETH3ADDR
        ip link set dev eth3 up
fi
