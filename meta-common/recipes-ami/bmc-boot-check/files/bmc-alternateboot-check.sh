#!/bin/sh

ADDRESS=0x1E620064

# Cleare FMC_WDT2 register value
VAL=$(devmem $ADDRESS)
valEnableWDT=$(($VAL & 1))

if [[ $valEnableWDT == 1 ]]
then
	devmem $ADDRESS 32 0x0
	VAL=$(devmem $ADDRESS)
	valBootSource=$((($VAL >> 4) & 1))
	if [[ $valBootSource == 1 ]]
	then
		VAL=$(cat /proc/mtd | awk '{print $4}' | awk -F'"' '$2=="alt-u-boot" {print $2}')
		if [[ -n $VAL ]]
		then
			devmem $ADDRESS 32 0xEA0000
			echo "0" > /run/media/slot
		fi
	fi
fi


