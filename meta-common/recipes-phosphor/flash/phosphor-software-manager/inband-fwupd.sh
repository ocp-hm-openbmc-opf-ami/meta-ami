#!/bin/bash
set -euo pipefail

outputfile=/tmp/fwupdate_inband_output.txt
TIMEOUT=40  # Set a timeout in seconds
SECONDS=0
getinterfacepath=""
tmppath=""
SIGNAL_RECEIVED=0
service="xyz.openbmc_project.Software.BMC.Updater"
software_obj="/xyz/openbmc_project/software"
target_interface="xyz.openbmc_project.Software.FirmwareUpdateTarget"
defaultTargets=()

echo "path=$1"

inband_tmppath=$1

# call dbus monitor to get software interface

busctl monitor --match "type='signal',sender='$service',member='InterfacesAdded'" > $outputfile &

# copy file to /tmp/images

cp $inband_tmppath /tmp/images/

while [ $SECONDS -lt $TIMEOUT ]; do
    if grep -q "Member=InterfacesAdded" $outputfile; then
        getinterfacepath=$(grep "OBJECT_PATH" $outputfile | awk '{ gsub(/[";]/, "", $2); print $2; exit }')
        tmppath="/tmp/images/$(basename "$getinterfacepath")"
        SIGNAL_RECEIVED=1
        break
    fi
    sleep 1
    SECONDS+=1
done

echo $getinterfacepath

rm -rf $outputfile


# set activation object

if [ $SIGNAL_RECEIVED -eq 0 ]; then
    echo "Timeout waiting for InterfacesAdded signal"
    exit 1
else
    busctl set-property $service $getinterfacepath xyz.openbmc_project.Software.Activation RequestedActivation s xyz.openbmc_project.Software.Activation.RequestedActivations.Active
fi
