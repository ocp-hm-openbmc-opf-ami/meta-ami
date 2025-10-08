#!/bin/sh

ADDRESS=0x1E620064

# Cleare FMC_WDT2 register value
VAL=$(devmem $ADDRESS)
valEnableWDT=$(($VAL & 1))

if [[ $valEnableWDT == 1 ]]
then
	devmem $ADDRESS 32 0x0
fi


