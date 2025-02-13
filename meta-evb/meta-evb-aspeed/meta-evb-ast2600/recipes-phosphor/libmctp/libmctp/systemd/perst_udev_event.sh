#!/bin/bash

source /usr/bin/bmc_state_files.sh

log()
{
    echo $1 | systemd-cat -t perst-udev-event
}

if [ ! -d "$STATE_FILE_PATH" ]; then
    mkdir $STATE_FILE_PATH
fi

log "PERST detected"

if [[ ! -f "$PERST_SIGNALLED_FILE" ]]; then
    touch $PERST_SIGNALLED_FILE
    systemctl restart bmc-pcie-init
else
    log "PERST signal being handled, no action taken"
fi

exit 0
