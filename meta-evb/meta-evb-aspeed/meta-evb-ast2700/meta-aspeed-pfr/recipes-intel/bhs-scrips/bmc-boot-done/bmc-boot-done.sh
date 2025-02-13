#!/bin/bash

GPIO_NAME="BMC_BOOT_DONE"

if gpio=$(gpiofind $GPIO_NAME); then
  echo "$GPIO_NAME asserted"
  gpioset --mode=signal $gpio=1
else
  echo "$GPIO_NAME not found"
  exit 1
fi
