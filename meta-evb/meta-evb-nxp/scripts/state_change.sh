#! /bin/bash
# Copyright 2025-2026 NXP

busctl set-property xyz.openbmc_project.State.BMC /xyz/openbmc_project/state/bmc0 xyz.openbmc_project.State.BMC CurrentBMCState s "xyz.openbmc_project.State.BMC.BMCState.Ready"

busctl set-property xyz.openbmc_project.State.Host /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.Host RequestedHostTransition s "xyz.openbmc_project.State.Host.Transition.On"
