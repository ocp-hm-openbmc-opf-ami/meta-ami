#!/bin/bash

# Define GPIO pins
GPIO_PINS=(PWRGD_S0_PWROK_CPU0 FP_PWR_BTN_PFR_N_BMC_IN)

# Define D-Bus property
DBUS_NAME=(PowerOk PowerButton)

# Define GPIO Passthrough
GPIO_PASS=(NULL FM_PWR_BTN_OUT_CPU0_N)

interrupt_handler() {
    echo "Received SIGINT. Stopping the loop."
    exit 0
}

trap interrupt_handler SIGINT

for ((i=0; i<2; i++)); do
     #Init GPIO
    gpio_pin[i]=$(gpiofind "${GPIO_PINS[$i]}")
    if [ -z "${gpio_pin[$i]}" ]; then
        echo "power-status-sync ${GPIO_PINS[$i]} not found"
        exit 1
    fi
    last_gpio_value[i]=2

    #Init GPIO PassThrough
    if [[ ${GPIO_PASS[$i]} != "NULL" ]]; then
        gpio_pass[i]=$(gpiofind "${GPIO_PASS[$i]}")
        if [ -z "${gpio_pass[$i]}" ]; then
            echo "power-status-sync ${GPIO_PASS[$i]} not found"
            exit 1
        fi
    fi
done

while true
do
    for ((i=0; i<2; i++)); do
        gpio_value=$(gpioget ${gpio_pin[$i]})

        if [ "$gpio_value" != "${last_gpio_value[$i]}" ]; then
            if [ "$gpio_value" -eq 0 ]; then
                busctl set-property xyz.openbmc_project.Inventory.Manager \
                    /xyz/openbmc_project/inventory/system/chassis/host0 \
                    xyz.openbmc_project.State.Host  "${DBUS_NAME[$i]}"  b false
            else
                busctl set-property xyz.openbmc_project.Inventory.Manager \
                    /xyz/openbmc_project/inventory/system/chassis/host0 \
                    xyz.openbmc_project.State.Host  "${DBUS_NAME[$i]}"  b true
            fi
            echo "power-status-sync get ${GPIO_PINS[$i]}=$gpio_value "

            #PassThrough GPIO value
            if [[ ${GPIO_PASS[$i]} != "NULL" ]]; then
                gpioset ${gpio_pass[$i]}=$gpio_value
                echo "power-status-sync set passthroug ${GPIO_PASS[$i]}=$gpio_value "
            fi
        fi
        last_gpio_value[i]=$gpio_value
    done
    sleep 0.1
done
