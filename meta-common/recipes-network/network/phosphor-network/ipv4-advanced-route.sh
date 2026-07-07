#!/bin/sh

# 1 - IFACE
# 2 - Default Gateway

IFACE="$1"
STATE="$2"
HOSTINTF=0
RT_TABLE="/etc/iproute2/rt_tables"
case "$IFACE" in
    bond*|bond*.*|lo)
        exit 0
        ;;
    hostusb*)
        HOSTINTF=1
        MODE="ipv4"
        ;;
    *)
        if ! [ -f "/etc/systemd/network/00-bmc-$IFACE.network" ]; then
            MODE="ipv4"
        else
            MODE=`awk -F'=' '/DHCP=/ {print $2}' /etc/systemd/network/00-bmc-$IFACE.network 2> /dev/null`
        fi
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

    read octetip1 octetip2 octetip3 octetip4 <<< "$octetip"
    read octetsn1 octetsn2 octetsn3 octetsn4 <<< "$octetsn"

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
    read IP CIDR NETMASK < <(
        ip -4 addr show dev $IFACE scope global | awk '
            /inet/ {
                    split($2,a,"/")   # a[1] = IP, a[2] = CIDR
                    cidr=a[2]
                    mask = (2**32 - 1) * (2**(32 - cidr))
                    netmask=""
                    for (i=3; i>=0; i--) {
                            octet = int(mask / 256^(i)) % 256
                            netmask = netmask octet (i>0?".":"")
                    }
                    print a[1], cidr, netmask
            }'
    )

    if [[ "$MODE" == "false" ]] || [[ "$MODE" == "ipv6" ]]; then
        GATEWAY=`awk -F"=" '/Gateway=/ && !/:/ {print $2}' /etc/systemd/network/00-bmc-$IFACE.network 2> /dev/null`
    elif [ $HOSTINTF -ne 1 ]; then
        GATEWAY=`ip route show default dev "$IFACE" | cut -d" " -f3`
    fi

    if [[ -z "$IP" ]] || [[ -z "$CIDR" ]] ; then
        exit 0
    fi

    NETADDR=$(NetworkAddress $IP $NETMASK $CIDR)

    grep -q "$IFACE" "$RT_TABLE"
    if [ $? -ne 0 ]; then
        NUM=`awk '!/^#/ {count++} END{print count}' "$RT_TABLE"`
        echo "$(($NUM + 255)) $IFACE" >> "$RT_TABLE"
    fi

    if [ $HOSTINTF -eq 1 ]; then
        if [ "$IFACE" == "hostusb0" ]; then
            ip route add 169.254.0.18 dev $IFACE table $IFACE 2> /dev/null
            ip route add 169.254.0.18 via 169.254.0.17 dev $IFACE metric 1 2> /dev/null
        elif [ "$IFACE" == "hostusb1" ]; then
            ip route add 169.254.10.18 dev $IFACE table $IFACE 2> /dev/null
            ip route add 169.254.10.18 via 169.254.10.17 dev $IFACE metric 1 2> /dev/null
        fi
    else
        if [[ -z "$GATEWAY" ]]; then
            exit 0
        fi

        METRIC=0
        ip route add default via $GATEWAY dev $IFACE table $IFACE metric $((METRIC++)) 2> /dev/null
        ip route add "$NETADDR/$CIDR" dev $IFACE table $IFACE 2> /dev/null
    fi

    ip rule del table $IFACE 2>/dev/null
    ip rule add from $IP table $IFACE 2> /dev/null

else
    ip rule del table $IFACE 2>/dev/null
    ip route flush table $IFACE 2>/dev/null
fi
