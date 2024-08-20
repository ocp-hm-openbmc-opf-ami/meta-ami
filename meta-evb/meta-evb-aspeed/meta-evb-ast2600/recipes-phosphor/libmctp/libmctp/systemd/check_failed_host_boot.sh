#!/bin/bash

source /usr/bin/bmc_state_files.sh

if [[ ! -f "$CPU_BOOT_COMPLETE_FILE" ]]; then
	touch $CPU_BOOT_TIMEOUT_FILE

	#
	# Host boot failed, so restart MCTP and GPU manager services anyhow
	#
	systemctl restart mctp-pcie-ctrl

	echo "Starting GpuMgr from cpu boot timeout service"
	dbus-send --system --type=signal /xyz/openbmc_project/GpuMgr xyz.openbmc_project.GpuMgr.Server.FORCE_SMBPBI_PCIE
	systemctl restart nvidia-gpu-manager
fi
