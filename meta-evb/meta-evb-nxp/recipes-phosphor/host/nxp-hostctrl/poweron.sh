#!/bin/bash
#SPDX-License-Identifier: MIT
#Copyright 2025-2026 NXP

power_on() {
    echo "Powering on Server"

sleep 1
gpioset 0 2=1
sleep 1
busctl set-property xyz.openbmc_project.State.Host /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.Host CurrentHostState s "xyz.openbmc_project.State.Host.HostState.Running"
sleep 1
}

power_on

exit 0;
