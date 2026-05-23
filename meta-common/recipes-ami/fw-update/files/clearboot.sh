#!/bin/bash

# clear boot source
if grep -qi "ast2700" /proc/device-tree/compatible 2>/dev/null; then
    ADDRESS=0x14c3744c
    OFFSET=0xEA000000
    BIT=1
else
    ADDRESS=0x1E620064
    OFFSET=0xEA0000
    BIT=4
fi

VAL=$(devmem $ADDRESS)
valBootSource=$((($VAL >> $BIT) & 1))
if [[ $valBootSource == 1 ]]
then
    VAL=$(cat /proc/mtd | awk '{print $4}' | awk -F'"' '$2=="alt-u-boot" {print $2}')
    if [[ -n $VAL ]]
    then
        devmem $ADDRESS 32 $OFFSET
        echo "0" > /run/media/slot
    fi
fi
