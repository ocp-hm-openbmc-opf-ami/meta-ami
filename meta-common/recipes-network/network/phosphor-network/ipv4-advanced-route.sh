#!/bin/sh

# 1 - IFACE
# 2 - Default Gateway

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

IPToOctets()
{
    ip_address=$1
    IFS=.
    set $ip_address
    octet1=$1
    octet2=$2
    octet3=$3
    octet4=$4
    echo $octet1 $octet2 $octet3 $octet4
}

NetworkAddress()
{
    ip_address=$1
    subnetmask=$2
    cidr=$3

    octetip=$(IPToOctets $ip_address)
    octetsn=$(IPToOctets $subnetmask)

    octetip1=$(echo $octetip | awk '{print $1}')
    octetip2=$(echo $octetip | awk '{print $2}')
    octetip3=$(echo $octetip | awk '{print $3}')
    octetip4=$(echo $octetip | awk '{print $4}')

    octetsn1=$(echo $octetsn | awk '{print $1}')
    octetsn2=$(echo $octetsn | awk '{print $2}')
    octetsn3=$(echo $octetsn | awk '{print $3}')
    octetsn4=$(echo $octetsn | awk '{print $4}')

    netaddress=$(($octetip1 & $octetsn1)).$(($octetip2 & $octetsn2)).$(($octetip3 & $octetsn3)).$(($octetip4 & $octetsn4))
    echo $netaddress
}

MaskToCidr() {
    nbits=0
    IFS=.
    for dec in $1 ; do
            case $dec in
                    255) let nbits+=8;;
                    254) let nbits+=7;;
                    252) let nbits+=6;;
                    248) let nbits+=5;;
                    240) let nbits+=4;;
                    224) let nbits+=3;;
                    192) let nbits+=2;;
                    128) let nbits+=1;;
                    0) ;;
            esac
    done
    echo "$nbits"
}

if [ "$STATE" == "UP" ]; then
    sleep 1;

    IP=`ifconfig "$IFACE" | grep "inet addr" | cut -d":" -f2 | awk '{print $1}'`

    NETMASK=`ifconfig "$IFACE" | grep "inet addr" | cut -d":" -f4 | awk '{print $1}'`

    if [[ "$MODE" == "false" ]] || [[ "$MODE" == "ipv6" ]]; then
        GATEWAY=`cat /etc/systemd/network/00-bmc-$IFACE.network 2> /dev/null | grep -i "Gateway=" | grep -v ":" | cut -d"=" -f2`
    else
        GATEWAY=`route -A inet | grep "$IFACE" | grep "UG" | awk '{print $2}'`
    fi

    if [[ -z "$IP" ]] || [[ -z "$NETMASK" ]] || [[ -z "$GATEWAY" ]]; then
        exit 0
    fi

    CIDR=$(MaskToCidr $NETMASK)
    NETADDR=$(NetworkAddress $IP $NETMASK $CIDR)

    METRIC=0

    ROUTE=`route -n | grep UG | grep $IFACE | awk '{print $2}' | uniq`
    if [ -z "$ROUTE" ]; then
        route add default gw $GATEWAY dev $IFACE metric $METRIC 2> /dev/null
    fi

    ip route add default via $GATEWAY dev $IFACE table $IFACE metric $((METRIC++)) 2> /dev/null
    ip route add "$NETADDR/$CIDR" dev $IFACE table $IFACE 2> /dev/null
    ip rule del table $IFACE 2>/dev/null
    ip rule add from $IP table $IFACE 2> /dev/null

else

    ip rule del table $IFACE 2>/dev/null
    ip route flush table $IFACE 2>/dev/null

fi