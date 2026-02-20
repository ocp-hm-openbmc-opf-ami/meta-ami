#!/bin/sh

ADDRESS=0x14c3740c
BOOT_INDICATOR_ADDR=0x14c3744c

# Cleare FMC_WDT2 register value
VAL=$(devmem $ADDRESS)
valEnableWDT=$(($VAL & 1))

if [[ $valEnableWDT == 1 ]]
then
        devmem $ADDRESS 32 0x0
fi

BOOT_INDICATOR_VAL=$(devmem $BOOT_INDICATOR_ADDR)
valBootInd=$(($BOOT_INDICATOR_VAL &1))

if [[ $valBootInd == 1 ]]
then
        devmem $BOOT_INDICATOR_ADDR 32 0x0
fi

