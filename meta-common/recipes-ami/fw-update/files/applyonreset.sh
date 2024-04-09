#!/bin/bash

if [ "$1" = "start" ]; then
    echo "started applyonreset service"
    exit 0
fi
# Get the current time
current_time=$(date +"%s")

directory="/tmp/images"

pattern1="xyz.openbmc_project.Software.ApplyTime.RequestedApplyTimes.OnReset"
pattern2="xyz.openbmc_project.Software.ApplyTime.RequestedApplyTimes.InMaintenanceWindowOnReset"

convert_seconds_to_date() {
    local seconds=$1
    date -d "@$seconds" +"%Y-%m-%d %H:%M:%S"
}
echo "Apply time on reset script "

# Check if the directory exists
if [ -d "$directory" ]; then
    # List directories only (excluding files) and print their names
    for folder in "$directory"/*/; do
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
            else
                echo "Current time is outside maintenance window."
            fi
        else
             echo "String does not match any pattern."
        fi
    done
else
    echo "Directory $directory does not exist."
fi