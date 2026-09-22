#!/bin/bash
#SPDX-License-Identifier: MIT
#Copyright 2025-2026 NXP

# Check current Host status. Do nothing when the Host is currently ON
st=$(busctl get-property xyz.openbmc_project.State.Host \
	/xyz/openbmc_project/state/host0 xyz.openbmc_project.State.Host \
	CurrentHostState | cut -d"." -f6)
if [ "$st" == "Running\"" ]; then
	exit 0
else
# Time out checking for Host ON is 60s
    cnt=60
    while [ "$cnt" -gt 0 ];
    do
	    cnt=$((cnt - 1))
	    sleep 1
    done
    gpioset 0 2=1
    busctl set-property xyz.openbmc_project.State.Host /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.Host CurrentHostState s "xyz.openbmc_project.State.Host.HostState.Running"
    exit 0
fi


