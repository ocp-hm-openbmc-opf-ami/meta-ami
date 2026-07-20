#!/bin/sh

# Define a list of processes to exclude (you can add more processes to this list as needed)
exclude_list=" bmcweb phosphor-image-updater phosphor-version-software-manager memorycritical memorywarning phosphor-network-manager dbus-broker phosphor-health-monitor mtd-util mtd_debug flashcp"

# Function to clear caches
clear_caches() {
    echo "Clearing caches..."

    # Clear pagecache, dentries, and inodes
    # sync && echo 3 | tee /proc/sys/vm/drop_caches

    # Clear systemd journal logs older than 1 day
    journalctl --vacuum-time=1d

    # Clear DNS cache (if using systemd-resolved)
    systemctl restart systemd-resolved

    # Clear slab cache
    # echo 1 > /proc/sys/vm/drop_caches

    # Clear swap cache
    # swapoff -a && swapon -a
}

# Loop through the list of top memory-consuming processes
while true; do
    # Clear caches after checking and killing the process
    clear_caches
    # Get the output from top, skip the header lines, and extract all the top memory-consuming processes
    top_processes=$(top -bm -n 1 | sed -n '5,$p')  # Skipping the first 4 lines (header)
    
    # Loop through each process in the list
    while IFS= read -r top_process; do
        # Extract PID, RSS (memory usage), and command name from the process line
        pid=$(echo "$top_process" | awk '{print $1}')
        rss=$(echo "$top_process" | awk '{print $2}')
        command=$(echo "$top_process" | awk '{print $9}' | sed 's/.*\///')

        # Check if the command is in the exclusion list
        if echo "$exclude_list" | grep -w -q "$command"; then
            # If excluded, skip this process and continue to the next one
            echo "$command is in the exclusion list, skipping."
        else
            # If not in exclusion list, output the process and kill it
            echo "Top memory-consuming service: $command (PID: $pid) using $rss KB of memory"
            service_file=$(systemctl status "$pid" 2>/dev/null | head -n 1 | awk -F'[*-]' '{print $2}')
            systemctl stop "$service_file"
            #kill "$pid"
            echo "$command has been stopped."
            
            # Exit the loop after killing the first valid process
            break 2  # Break both inner and outer loops
        fi
    done <<< "$top_processes"

    # Optionally, add a short delay if you want to prevent constant CPU usage
    # sleep 1
done
