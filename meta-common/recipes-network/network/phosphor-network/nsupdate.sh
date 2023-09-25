#!/bin/sh
TSIG_KEY_DIR="/etc/dns.d/"

if [ "$1" == "deregister" ]; then
    if [ -n "$2" ]; then
        FILES="/etc/dns.d/nsupdate_tmp-del-$2"
    else
        FILES="/etc/dns.d/nsupdate_tmp-del"
    fi

    for i in "$FILES"*; do
        if ! [ -f $i ]; then
            continue
        fi

        IFACE=`echo $i | cut -d"_" -f2 | cut -d"-" -f3`
        UseTSIG=`sed -n "/^\[$IFACE\]/,/\[.*\]/p" /etc/dns.d/dns.conf.bak | grep UseTSIG | cut -d"=" -f2`
        echo "UseTSIG: $UseTSIG"
        if [ "$UseTSIG" == "true" ]; then
            TSIG_KEY_FILE=$TSIG_KEY_DIR"tsig_"$IFACE"_prev.private"
            if [ -f "$TSIG_KEY_FILE" ]; then
                TSIG_KEY_NAME=`grep "filename:" $TSIG_KEY_FILE | awk {'print $2'} | cut -d "+" -f1 | sed 's/^.//' | sed 's/.$//'`
                TSIG_KEY_METHOD=`grep "Algorithm" $TSIG_KEY_FILE | awk '{print substr($3, 1, length($3) -1 )}' | awk '{print substr($1, 2)}' | awk '{gsub("_", "-", $1); print tolower($1)}'`
                TSIG_KEY_SECRET=`grep "Key" $TSIG_KEY_FILE | awk -F": " '{print $2}'`
                if [ -z "$TSIG_KEY_METHOD" ]; then
                    TSIG_KEY_METHOD=`grep "algorithm" $TSIG_KEY_FILE | awk '{print $2}'| sed 's/;//g'  | awk '{gsub("_", "-", $1); print tolower($1)}'`
                    TSIG_KEY_NAME=`grep "key " $TSIG_KEY_FILE | cut -d "\"" -f2`
                    TSIG_KEY_SECRET=`grep "secret" $TSIG_KEY_FILE | awk '{print $2}' | sed 's/\"//g' | sed 's/;//g'`
                fi

                nsupdate -v -y $TSIG_KEY_METHOD:$TSIG_KEY_NAME:$TSIG_KEY_SECRET $i &
            else
                echo "$IFACE No TSIG found..."
                continue
            fi
        else
            nsupdate $i &
        fi
        echo "$i"
        COUNT=0
        while [ $COUNT != 3 ];
        do
            COUNT=$(($COUNT+1))
            ps | grep -v grep | grep -q "nsupdate.*$i"
            if [ $? != 0 ]; then
                break
            fi
            sleep 1
        done

        if [ $COUNT == 3 ]; then
            ps | grep "nsupdate.*$i" | grep -v grep| awk '{print $1}' | xargs kill > /dev/null 2>&1
        fi
    done
elif [ "$1" == "register" ]; then
    ENABLED=`busctl get-property xyz.openbmc_project.Network /xyz/openbmc_project/network/dhcp xyz.openbmc_project.Network.DHCPConfiguration SendNsupdateEnabled | cut -d" " -f2`
    if [ "$ENABLED" = "true" ]; then
        if [ -n "$2" ]; then
            FILES="/etc/dns.d/nsupdate_tmp-add-$2"
        else
            FILES="/etc/dns.d/nsupdate_tmp-add"
        fi

        for i in "$FILES"*; do
            if ! [ -f $i ]; then
                continue
            fi

            IFACE=`echo $i | cut -d"_" -f2 | cut -d"-" -f3`
            UseTSIG=`sed -n "/^\[$IFACE\]/,/\[.*\]/p" /etc/dns.d/dns.conf | grep UseTSIG | cut -d"=" -f2`
            if [ "$UseTSIG" == "true" ]; then
                TSIG_KEY_FILE=$TSIG_KEY_DIR"tsig_$IFACE.private"
                if [ -f "$TSIG_KEY_FILE" ]; then
                    TSIG_KEY_NAME=`grep "filename:" $TSIG_KEY_FILE | awk {'print $2'} | cut -d "+" -f1 | sed 's/^.//' | sed 's/.$//'`
                    TSIG_KEY_METHOD=`grep "Algorithm" $TSIG_KEY_FILE | awk '{print substr($3, 1, length($3) -1 )}' | awk '{print substr($1, 2)}' | awk '{gsub("_", "-", $1); print tolower($1)}'`
                    TSIG_KEY_SECRET=`grep "Key" $TSIG_KEY_FILE | awk -F": " '{print $2}'`
                    if [ -z "$TSIG_KEY_METHOD" ]; then
                        TSIG_KEY_METHOD=`grep "algorithm" $TSIG_KEY_FILE | awk '{print $2}'| sed 's/;//g'  | awk '{gsub("_", "-", $1); print tolower($1)}'`
                        TSIG_KEY_NAME=`grep "key " $TSIG_KEY_FILE | cut -d "\"" -f2`
                        TSIG_KEY_SECRET=`grep "secret" $TSIG_KEY_FILE | awk '{print $2}' | sed 's/\"//g' | sed 's/;//g'`
                    fi

                    nsupdate -v -y $TSIG_KEY_METHOD:$TSIG_KEY_NAME:$TSIG_KEY_SECRET $i &

                    if [ -f $TSIG_KEY_DIR"tsig_"$IFACE"_prev.private" ]; then
                        diff -q $TSIG_KEY_FILE $TSIG_KEY_DIR"tsig_"$IFACE"_prev.private"
                        if [ $? != 0 ]; then
                            cp -f $TSIG_KEY_FILE $TSIG_KEY_DIR"tsig_"$IFACE"_prev.private"
                        fi
                    else
                        cp $TSIG_KEY_FILE $TSIG_KEY_DIR"tsig_"$IFACE"_prev.private"
                    fi
                else
                    echo "$IFACE No TSIG found..."
                    continue
                fi
            else
                nsupdate $i &
            fi
            echo "$i"
            COUNT=0
            while [ $COUNT != 3 ];
            do
                COUNT=$(($COUNT+1))
                ps | grep -v grep | grep -q "nsupdate.*$i"
                if [ $? != 0 ]; then
                    break
                fi

                sleep 1
            done

            if [ $COUNT == 3 ]; then
                ps | grep "nsupdate.*$i" | grep -v grep| awk '{print $1}' | xargs kill > /dev/null 2>&1
            fi
        done
    fi
else
    echo "Nsupdate does nothing..."
fi
# busctl set-property xyz.openbmc_project.Network /xyz/openbmc_project/network/dns xyz.openbmc_project.Network.DDNS SetInProgress b false
