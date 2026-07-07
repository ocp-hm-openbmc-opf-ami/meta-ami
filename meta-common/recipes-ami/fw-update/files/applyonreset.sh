#!/bin/bash

if [ "$1" = "start" ]; then
    echo "started applyonreset service"
    if ! swapon --show=NAME | grep -q "^/dev/zram0$"; then
        echo "zram0 device found, enabling swap to improve memory management and prevent potential out-of-memory issues ..."
        /sbin/swapon /dev/zram0
    else
        echo "zram0 swap already enabled."
    fi    
    exit 0
fi


# Get the current time
current_time=$(date +%s)

directory="/tmp/images"

pattern1="xyz.openbmc_project.Software.ApplyTime.RequestedApplyTimes.OnReset"
pattern2="xyz.openbmc_project.Software.ApplyTime.RequestedApplyTimes.InMaintenanceWindowOnReset"
rtn_status=1

convert_seconds_to_date() {
    local seconds=$1
    date -u -d "@$seconds" +"%Y-%m-%d %H:%M:%S"
}
echo "Apply time on reset script "

# Check if the directory exists
if [ -d "$directory" ]; then
    # List directories only (excluding files) and print their names
    for folder in "$directory"/*/; do
        [[ "$folder" == *-pldm/ ]] && continue # Skip directories ending with -pldm
        # Extract folder name from full path
        folder_name=$(basename "$folder")
        echo "$folder_name"
        applytime=$(busctl get-property xyz.openbmc_project.Software.BMC.Updater \
            /xyz/openbmc_project/software/$folder_name \
            xyz.openbmc_project.Software.ApplyTime RequestedApplyTime \
            | awk '{print $2}' | tr -d '"')
        echo "applytime = $applytime"
        if [[ "$applytime" == "$pattern1" ]]; then
            echo "String matches pattern1."
            /usr/bin/fwupd.sh $folder_name
            rtn_status=$(echo $?)
        elif [[ "$applytime" == "$pattern2" ]]; then
            maintenanceSeconds=$(busctl get-property xyz.openbmc_project.Software.BMC.Updater \
            /xyz/openbmc_project/software/$folder_name \
            xyz.openbmc_project.Software.ApplyTime MaintenanceWindowStartTime \
            | awk '{print $2}' | tr -d '"')
            maintenanceDuaration=$(busctl get-property xyz.openbmc_project.Software.BMC.Updater \
            /xyz/openbmc_project/software/$folder_name \
            xyz.openbmc_project.Software.ApplyTime MaintenanceWindowDurationInSeconds \
            | awk '{print $2}' | tr -d '"')
            maintenanceStartTime=$maintenanceSeconds
            maintenanceEndTime=$(($maintenanceSeconds + $maintenanceDuaration))
            
            echo "Maintenance Window Start Time: $(convert_seconds_to_date $maintenanceStartTime)"
            echo "Maintenance Window End Time: $(convert_seconds_to_date $maintenanceEndTime)"
            
            if [[ $current_time -ge $maintenanceStartTime && $current_time -lt $maintenanceEndTime ]]; then
                echo "Current time is within maintenance window."
                # Execute fwupd.sh only if the current time is within the maintenance window
                /usr/bin/fwupd.sh $folder_name
                rtn_status=$(echo $?)
            else
                echo "Current time is outside maintenance window."
            fi
        else
             echo "String does not match any pattern."
        fi

        if test -x $directory/$folder_name; then
            # Update Activation status
            if [ "$rtn_status" == "0" ]; then
                busctl set-property xyz.openbmc_project.Software.BMC.Updater \
                    /xyz/openbmc_project/software/$folder_name \
                    xyz.openbmc_project.Software.Activation Activation \
                    s "xyz.openbmc_project.Software.Activation.Activations.Active"
            else
                busctl set-property xyz.openbmc_project.Software.BMC.Updater \
                    /xyz/openbmc_project/software/$folder_name \
                    xyz.openbmc_project.Software.Activation Activation \
                    s "xyz.openbmc_project.Software.Activation.Activations.Failed"
            fi
            # Clear tmp images
            rm -rf $directory/$folder_name
        fi
    done
else
    echo "Directory $directory does not exist."
fi
