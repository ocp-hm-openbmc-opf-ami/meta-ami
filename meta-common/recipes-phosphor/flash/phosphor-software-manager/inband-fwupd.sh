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

# get default target paths


mapfile -t defaultTargets < <(
    busctl --system call "xyz.openbmc_project.ObjectMapper" /xyz/openbmc_project/object_mapper \
        "xyz.openbmc_project.ObjectMapper" GetSubTreePaths sias /xyz/openbmc_project/software \
        0 1 xyz.openbmc_project.Software.Version | grep -Eo '/xyz/openbmc_project/software/[^[:space:]]+' | awk -F'/' '{gsub(/"/,"",$NF); print $NF}' \
        | sort -u
)
echo "Default Targets: ${defaultTargets[@]}"

if [ -f "$tmppath/image-bmc" ] && [[ " ${defaultTargets[*]} " =~ " bmc_active " ]]; then
        target="bmc_active"
elif [ -f "$tmppath/image-bios" ] && [[ " ${defaultTargets[*]} " =~ " bios_active " ]]; then
        target="bios_active"
elif [ -f "$tmppath/image-cpld" ] && [[ " ${defaultTargets[*]} " =~ (^|[[:space:]])cpld_[^[:space:]]+([[:space:]]|$) ]]; then
    cpld_targets=($(printf '%s\n' "${defaultTargets[@]}" | grep '^cpld_'))
    if [ ${#cpld_targets[@]} -gt 1 ]; then
        echo "Error: Multiple CPLD targets found: ${cpld_targets[*]}"
        exit 1
    fi
    target="${cpld_targets[0]}"
elif [ -f "$tmppath/image-raid" ]; then
    raid_targets=($(printf '%s\n' "${defaultTargets[@]}" | grep -iE '^(raid|hba|ctrl)_'))
    if [ ${#raid_targets[@]} -gt 1 ]; then
        echo "Error: Multiple RAID/HBA/CTRL targets found: ${raid_targets[*]}"
        exit 1
    elif [ ${#raid_targets[@]} -eq 1 ]; then
        target="${raid_targets[0]}"
    fi
fi

# set push uri target

busctl set-property $service $software_obj $target_interface HttpPushUriTargets as 1 "$target" || true
busctl set-property $service $software_obj $target_interface HttpPushUriTargetsBusy b true || true


# set activation object

if [ $SIGNAL_RECEIVED -eq 0 ]; then
    echo "Timeout waiting for InterfacesAdded signal"
    exit 1
else
    busctl set-property $service $getinterfacepath xyz.openbmc_project.Software.Activation RequestedActivation s xyz.openbmc_project.Software.Activation.RequestedActivations.Active
fi