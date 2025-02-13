#!/bin/bash

source /usr/bin/bmc_functions.sh

RUN_MCTP=`run_mctp`

touch $MCTP_FIRST_TIME_INIT_FILE

if [[ "$RUN_MCTP" == "1" ]]; then
    echo "Starting MCTP service with the following args: $MCTP_PCIE_CTRL_OPTS"

    # Notify systemd that service has started
    systemd-notify --ready --status="starting /usr/bin/mctp-pcie-ctrl process"

    /usr/bin/mctp-pcie-ctrl $MCTP_PCIE_CTRL_OPTS
else
    echo "Waiting for host to boot to start MCTP..."

    systemd-run --on-active=180 /usr/bin/check_failed_host_boot.sh

    #
    # Need to add this or the script will just exit and systemd will restart it
    #
    tail -f /dev/null
fi
