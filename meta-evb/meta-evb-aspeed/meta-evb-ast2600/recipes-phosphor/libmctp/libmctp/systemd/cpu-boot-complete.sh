#!/bin/bash

source /usr/bin/bmc_state_files.sh

touch $CPU_BOOT_COMPLETE_FILE

if [[ ! -f "$CPU_BOOT_TIMEOUT_FILE" ]]; then
	# Start GpuMgr after boot complete
	echo "Starting GpuMgr from cpu boot complete service"
	dbus-send --system --type=signal /xyz/openbmc_project/GpuMgr xyz.openbmc_project.GpuMgr.Server.FORCE_SMBPBI_PCIE
	systemctl restart nvidia-gpu-manager
fi

#
# Host boot complete, so start MCTP service
# NOTE: We always restart mctp when we receive a boot complete.
#       If we do not we can miss the SatMC endpoint
#
systemctl restart mctp-pcie-ctrl
