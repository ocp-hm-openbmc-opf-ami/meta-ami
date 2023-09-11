#!/bin/sh
#Add rules for IPv6
IFACE="$1"
STATE="$2"

case "$IFACE" in
    bond*|bond*.*|lo)
        exit 0
        ;;
    *.*)
        MODE=`cat /etc/systemd/network/00-bmc-$(echo $IFACE | cut -d"." -f1 ).network 2> /dev/null | grep "DHCP=" | cut -d"=" -f2`
        ;;
    *)
        MODE=`cat /etc/systemd/network/00-bmc-$IFACE.network 2> /dev/null | grep "DHCP=" | cut -d"=" -f2`
        ;;
esac

ROUTE_RULE="/tmp/route_rule"
FIRST_ADD=0


if [ "$STATE" == "UP" ]; then

    count=`ifconfig $IFACE | grep "inet6 addr" | grep -v "Link" | awk '{print $3}' | cut -d"/" -f1 | wc -l`
    if [ $count -eq 0 ]; then
        exit 0
    fi

    ip -6 route | grep "$IFACE" >> $ROUTE_RULE.$IFACE"_tmp"

    if [ ! -f "$ROUTE_RULE.$IFACE" ]; then
        touch $ROUTE_RULE.$IFACE
        FIRST_ADD=1
    fi

    ip -6 route flush table $IFACE 2>/dev/null

    if [[ "$MODE" == "false" ]] || [[ "$MODE" == "ipv4" ]]; then
        GATEWAY6=`cat /etc/systemd/network/00-bmc-$IFACE.network 2> /dev/null | grep -i "Gateway=" | grep ":" | cut -d"=" -f2`
        ip -6 route add default via $GATEWAY6 dev $IFACE table $IFACE > /dev/null 2>&1
    else
        GATEWAY6=`cat $ROUTE_RULE.$IFACE"_tmp" | grep "default" | awk '{print $3}' | cut -d"/" -f 1`
        if [ -z "$GATEWAY6" ]; then
            GATEWAY6=`cat $ROUTE_RULE.$IFACE"_tmp" | grep "nexthop" | awk '{print $3}' | cut -d"/" -f 1`
            if [ -n "$GATEWAY6" ]; then
                ip -6 route add default via $GATEWAY6 dev $IFACE table $IFACE > /dev/null 2>&1
            fi
        fi
        ip -6 route add default via $GATEWAY6 dev $IFACE table $IFACE > /dev/null 2>&1
    fi

    count=`cat $ROUTE_RULE.$IFACE"_tmp" | grep -v "default" | grep -v "nexthop" | wc -l`
    i=0
    while ( [ $count -gt 0 ] )
    do
        i=$((i + 1))

        ROUTE=`cat $ROUTE_RULE.$IFACE"_tmp" | awk '{print $1}' |  awk 'NR=='$i''`
        # echo "ROUTE = $ROUTE"
        if [ -n "$ROUTE" ]; then
            ip -6 route add "$ROUTE" dev $IFACE table $IFACE > /dev/null 2>&1
        fi

        count=$((count - 1))
    done

    ip -6 route show table $IFACE | grep "dev $IFACE" > $ROUTE_RULE.$IFACE

    count=`ifconfig $IFACE | grep "inet6 addr" | grep -v "Link" | awk '{print $3}' | cut -d"/" -f1 | wc -l`
    ip -6 rule flush table $IFACE 2>/dev/null
    i=1
    while ( [ $count -gt 0 ] )
    do
        IPV6_ADDR=`ifconfig $IFACE | grep "inet6 addr" | grep -v "Link" | awk '{print $3}' | cut -d"/" -f1 | awk 'NR=='$i''`
        ip -6 rule add from $IPV6_ADDR table $IFACE > /dev/null 2>&1
        i=$((i + 1))
        count=$((count - 1))
    done

    rm $ROUTE_RULE.$IFACE"_tmp"

else

    ip -6 rule flush table $IFACE 2>/dev/null
    ip -6 route flush table $IFACE 2>/dev/null
fi