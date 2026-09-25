#!/bin/bash
#SPDX-License-Identifier: MIT
#Copyright 2025-2026 NXP

power_off() {
    echo "Powering off Server"
    gpioset 0 2=0
    sleep 1
    busctl set-property xyz.openbmc_project.State.Host /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.Host CurrentHostState s "xyz.openbmc_project.State.Host.HostState.Off"
}

power_off

exit 0;
