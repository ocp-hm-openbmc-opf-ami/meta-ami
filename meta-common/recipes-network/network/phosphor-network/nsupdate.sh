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

        IFACE=`echo $i | awk -F[_-] '{print $4}'`
        read UseTSIG < <(awk -v iface="$IFACE" '
            $0 == "[" iface "]" {inblock=1; next}
            inblock && /^\[.*\]/ {inblock=0}
            inblock && /UseTSIG/ {split($0,a,"="); print a[2]} 
        ' /etc/dns.d/dns.conf.bak)
        echo "UseTSIG: $UseTSIG"
        if [ "$UseTSIG" == "true" ]; then
            TSIG_KEY_FILE=$TSIG_KEY_DIR"tsig_"$IFACE"_prev.private"
            if [ -f "$TSIG_KEY_FILE" ]; then
                unset TSIG_KEY_NAME TSIG_KEY_METHOD TSIG_KEY_SECRET

                eval $(awk -F": " '
                            /filename:/ {split($2,a,"+"); val = substr(a[1],2,length(a[1])-2); print "TSIG_KEY_NAME=\"" val "\""}
                            /Algorithm/ {split($2, a, " "); val = substr(a[2],2,length(a[2])-2); print "val="a[2]; gsub("_","-",val); val = tolower(val); print "TSIG_KEY_METHOD=\"" val "\""}
                            /Key/ {print "TSIG_KEY_SECRET=\"" $2 "\""}
                        ' $TSIG_KEY_FILE
                )

                if [ -z "$TSIG_KEY_METHOD" ]; then
                    eval $(
                        awk '
                            /algorithm/ {val=substr($2,1, length($2)-1); gsub("_", "-", val); print "TSIG_KEY_METHOD="tolower(val)}
                            /key/ {split($2, a, "\""); print "TSIG_KEY_NAME="a[2]}
                            /secret/ {split($2, a, "\""); print "TSIG_KEY_SECRET="a[2]}
                        ' $TSIG_KEY_FILE
                    )
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
            ps | awk -v file="nsupdate.*$i" '!/awk/ && $0 ~ file {found=1;} END {if (found==1) {exit 0} else {exit 1}}'
            if [ $? != 0 ]; then
                break
            fi
            sleep 1
        done

        if [ $COUNT == 3 ]; then
            ps | awk -v file="nsupdate.*$i" '!/awk/ && $0 ~ file {found=1; pid=$1}' | xargs kill
        fi
    done
elif [ "$1" == "register" ]; then
    ENABLED=`busctl get-property xyz.openbmc_project.Network /xyz/openbmc_project/network/dns xyz.openbmc_project.Network.DDNS SendNsupdateEnabled | cut -d" " -f2`
    if [ "$ENABLED" = "true" ] || [ "$3" = "force" ]; then
        if [ -n "$2" ]; then
            FILES="/etc/dns.d/nsupdate_tmp-add-$2"
        else
            FILES="/etc/dns.d/nsupdate_tmp-add"
        fi

        for i in "$FILES"*; do
            if ! [ -f $i ]; then
                continue
            fi

            IFACE=`echo $i | awk -F[_-] '{print $4}'`
            read UseTSIG < <(awk -v iface="$IFACE" '
                $0 == "[" iface "]" {inblock=1; next}
                inblock && /^\[.*\]/ {inblock=0}
                inblock && /UseTSIG/ {split($0,a,"="); print a[2]} 
            ' /etc/dns.d/dns.conf)
            echo "UseTSIG: $UseTSIG"
            if [ "$UseTSIG" == "true" ]; then
                TSIG_KEY_FILE=$TSIG_KEY_DIR"tsig_$IFACE.private"
                if [ -f "$TSIG_KEY_FILE" ]; then
                    unset TSIG_KEY_NAME TSIG_KEY_METHOD TSIG_KEY_SECRET

                    eval $(awk -F": " '
                            /filename:/ {split($2,a,"+"); val = substr(a[1],2,length(a[1])-2); print "TSIG_KEY_NAME=\"" val "\""}
                            /Algorithm/ {split($2, a, " "); val = substr(a[2],2,length(a[2])-2); print "val="a[2]; gsub("_","-",val); val = tolower(val); print "TSIG_KEY_METHOD=\"" val "\""}
                            /Key/ {print "TSIG_KEY_SECRET=\"" $2 "\""}
                        ' $TSIG_KEY_FILE
                    )
                    if [ -z "$TSIG_KEY_METHOD" ]; then
                        eval $(
                            awk '
                                /algorithm/ {val=substr($2,1, length($2)-1); gsub("_", "-", val); print "TSIG_KEY_METHOD="tolower(val)}
                                /key/ {split($2, a, "\""); print "TSIG_KEY_NAME="a[2]}
                                /secret/ {split($2, a, "\""); print "TSIG_KEY_SECRET="a[2]}
                            ' $TSIG_KEY_FILE
                        )
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
                ps | awk -v file="nsupdate.*$i" '!/awk/ && $0 ~ file {found=1;} END {if (found==1) {exit 0} else {exit 1}}'
                if [ $? != 0 ]; then
                    break
                fi

                sleep 1
            done

            if [ $COUNT == 3 ]; then
                ps | awk -v file="nsupdate.*$i" '!/awk/ && $0 ~ file {found=1; pid=$1}' | xargs kill
            fi
        done
    fi
else
    echo "Nsupdate does nothing..."
fi
# busctl set-property xyz.openbmc_project.Network /xyz/openbmc_project/network/dns xyz.openbmc_project.Network.DDNS SetInProgress b false
