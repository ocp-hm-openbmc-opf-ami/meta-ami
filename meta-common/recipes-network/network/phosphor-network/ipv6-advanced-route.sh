#!/bin/sh
#Add rules for IPv6
IFACE="$1"
STATE="$2"
RT_TABLE="/etc/iproute2/rt_tables"
case "$IFACE" in
    bond*|bond*.*|lo)
        exit 0
        ;;
    *)
        if ! [ -f "/etc/systemd/network/00-bmc-$IFACE.network" ]; then
            MODE="ipv6"
        else
            MODE=`cat /etc/systemd/network/00-bmc-$IFACE.network 2> /dev/null | grep "DHCP=" | cut -d"=" -f2`
        fi
        ;;
esac

ROUTE_RULE="/tmp/route_rule"
FIRST_ADD=0


if [ "$STATE" == "UP" ]; then

    count=`ip -6 addr show dev $IFACE scope global | awk '/inet6/ {split($2,a,"/"); count++} END {print count}'`
    if [ "${count:-0}" -eq 0 ]; then
        exit 0
    fi

    staticRtrEnable=`grep "IPv6EnableStaticRtr" "/etc/interface/$IFACE" 2> /dev/null | cut -d"=" -f2`
    if [ "$staticRtrEnable" = "true" ]; then
        staticRtr1=`grep "IPv6StaticRtrAddr" "/etc/interface/$IFACE"  | cut -d"=" -f2`
        staticRtr1Prefix=`grep "IPv6StaticRtrPrefix" "/etc/interface/$IFACE" | cut -d"=" -f2`
        ip -6 route add "$staticRtr1""/""$staticRtr1Prefix" dev $IFACE > /dev/null 2>&1

        staticRtr2=`grep "IPv6StaticRtr2Addr" "/etc/interface/$IFACE"  | cut -d"=" -f2`
        staticRtr2Prefix=`grep "IPv6StaticRtr2Prefix" "/etc/interface/$IFACE" | cut -d"=" -f2`
        ip -6 route add "$staticRtr2""/""$staticRtr2Prefix" dev $IFACE > /dev/null 2>&1
    fi

    ip -6 route | grep "$IFACE" >> $ROUTE_RULE.$IFACE"_tmp"

    if [ ! -f "$ROUTE_RULE.$IFACE" ]; then
        touch $ROUTE_RULE.$IFACE
        FIRST_ADD=1
    fi

    grep -q "$IFACE" "$RT_TABLE"
    if [ $? -ne 0 ]; then
        NUM=`grep -v "#" "$RT_TABLE" | wc -l`
        echo "$(($NUM + 255)) $IFACE" >> "$RT_TABLE"
    fi

    ip -6 route flush table $IFACE 2>/dev/null

    if [[ "$MODE" == "false" ]] || [[ "$MODE" == "ipv4" ]]; then
        GATEWAY6=`awk -F"=" '/Gateway=/ && /:/ {print $2}' /etc/systemd/network/00-bmc-$IFACE.network`
        [ -n "$GATEWAY6" ] && ip -6 route add default via $GATEWAY6 dev $IFACE table $IFACE > /dev/null 2>&1
    else
        GATEWAY6=`awk '/default/ {split($3, a, "/"); print a[1]}' $ROUTE_RULE.$IFACE"_tmp"`
        if [ -z "$GATEWAY6" ]; then
            GATEWAY6=`awk '/nexthop/ {split($3, a, "/"); print a[1]}' $ROUTE_RULE.$IFACE"_tmp"`
            [ -n "$GATEWAY6" ] && ip -6 route add default via $GATEWAY6 dev $IFACE table $IFACE > /dev/null 2>&1
        fi
        ip -6 route add default via $GATEWAY6 dev $IFACE table $IFACE > /dev/null 2>&1
    fi

    awk '{print $1}' $ROUTE_RULE.$IFACE"_tmp" | while read ROUTE
    do
        [ -n "$ROUTE" ] && ip -6 route add "$ROUTE" dev $IFACE table $IFACE > /dev/null 2>&1
    done

    ip -6 route show table $IFACE | grep "dev $IFACE" > $ROUTE_RULE.$IFACE
    ip -6 rule flush table $IFACE 2>/dev/null
    IPV6_ADDRS=$(ip -6 addr show dev "$IFACE" scope global | grep inet6 | awk '{split($2,a,"/"); print a[1]}')
    for IPV6_ADDR in $IPV6_ADDRS; do
        if [ -n "$IPV6_ADDR" ]; then
            ip -6 route add "$IPV6_ADDR" dev "$IFACE" table "$IFACE" > /dev/null 2>&1
            ip -6 route add "$IPV6_ADDR" dev "$IFACE" table main > /dev/null 2>&1
            ip -6 rule add from "$IPV6_ADDR" table "$IFACE" > /dev/null 2>&1
        fi
    done
    rm $ROUTE_RULE.$IFACE"_tmp"

else
    ip -6 rule flush table $IFACE 2>/dev/null
    ip -6 route flush table $IFACE 2>/dev/null
fi