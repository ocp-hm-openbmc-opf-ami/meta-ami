#!/bin/bash

# Source MCTP helper libraries
. /usr/libexec/mctp/mctp-i2c-hotplug.sh 2>/dev/null || true
. /usr/libexec/mctp/mctp-i2c-arp.sh 2>/dev/null || true
. /usr/libexec/mctp/mctp-i3c-rescan.sh 2>/dev/null || true
. /usr/libexec/mctp/mctp-get-routing-table.sh 2>/dev/null || true
. /usr/libexec/mctp/mctp-i3c-cleanup.sh 2>/dev/null || true

SERVICE="au.com.codeconstruct.MCTP1"
BASE_PATH="/au/com/codeconstruct/mctp1"
BUSOWNER_IFACE="au.com.codeconstruct.MCTP.BusOwner1"
MCTP_CONF="/usr/share/mctp/mctp_ext_options.json"

MCTP_PCIE="${MCTP_PCIE:=false}"
MCTP_I2C="${MCTP_I2C:=false}"
MCTP_I3C="${MCTP_I3C:=false}"
MCTP_USB="${MCTP_USB:=false}"
MCTP_I2C_ARP_MODE="${MCTP_I2C_ARP_MODE:=false}"
MCTP_PCIE_ROLE="${MCTP_PCIE_ROLE:-endpoint}"

# Parse command-line arguments (before reading conf so --conf= takes effect)
while [[ $# -gt 0 ]]; do
	case "$1" in
		--conf=*) MCTP_CONF="${1#*=}" ;;
		--mctp-pcie)  MCTP_PCIE="true" ;;
		--mctp-i2c)   MCTP_I2C="true" ;;
		--mctp-i3c)   MCTP_I3C="true" ;;
		--mctp-usb)   MCTP_USB="true" ;;
		--mctp-i2c-arp) MCTP_I2C_ARP_MODE="true" ;;
		--mctp-pcie-role=*) MCTP_PCIE_ROLE="${1#*=}" ;;
		*) echo "Unknown option: $1" >&2 ;;
	esac
	shift
done

# Reflect additional settings from mctp_ext_options.json
if [ -f "$MCTP_CONF" ]; then
	eval "$(python3 -c "
import json, sys
with open('$MCTP_CONF') as f:
    data = json.load(f)
for item in data:
    for exp in item.get('Exposes', []):
        t = exp.get('Type', '')
        if t == 'MCTPI2CConfiguration':
            arp = exp.get('ArpEnabled', '')
            if arp == 'enabled':
                print('mctp_i2c_arp_mode=true')
            elif arp == 'disabled':
                print('mctp_i2c_arp_mode=false')
            net = exp.get('Net', '')
            if net:
                print(f'mctp_i2c_net={net}')
        elif t == 'MCTPI3CConfiguration':
            net = exp.get('Net', '')
            if net:
                print(f'mctp_i3c_net={net}')
        elif t == 'MCTPPCIeConfiguration':
            role = exp.get('Role', '')
            if role:
                print(f'mctp_pcie_role={role}')
" 2>/dev/null)"

	# Map config values into variables used by this script (if present)
	[[ -n "$mctp_i2c_arp_mode" ]] && MCTP_I2C_ARP_MODE="$mctp_i2c_arp_mode"
	[[ -n "$mctp_i2c_net" ]] && MCTP_I2C_NET="$mctp_i2c_net"
	[[ -n "$mctp_i3c_net" ]] && MCTP_I3C_NET="$mctp_i3c_net"
	[[ -n "$mctp_pcie_role" ]] && MCTP_PCIE_ROLE="$mctp_pcie_role"
fi

cleanup() {
    log "Discovery service stopping cleanly..."
    exit 0
}
trap cleanup INT TERM

log() {
    echo "$1" | systemd-cat -t mctp-discovery
}

# Check if MCTP service exists
if ! busctl list | grep -q "$SERVICE"; then
    log "Error: D-Bus service $SERVICE not found"
    exit 1
fi

# Initialize I3C busowner devices from configuration array
echo "DEBUG: Checking if /tmp/.mctp_reset_done exists"
if [ ! -f /tmp/.mctp_reset_done ]; then
	echo "DEBUG: Reset marker not found, proceeding with setup"
	log "No reset marker file found, starting initial setup..."
	echo "DEBUG: MCTP_I3C variable value: $MCTP_I3C"
	if [[ "$MCTP_I3C" = "true" ]]; then
		echo "DEBUG: MCTP_I3C is true, parsing devices..."

		# Parse and setup all I3C busowner devices from mctp_ext_options.json
		while IFS='|' read -r device_name bus_num pid_mask device_pid role is_secondary is_i3c_target; do
			echo "DEBUG: Read device - $device_name | $bus_num | $pid_mask | $device_pid | $role | $is_secondary | $is_i3c_target"
			[ -z "$device_name" ] && continue
			echo "Processing I3C device: $device_name | Bus: $bus_num | PID Mask: $pid_mask | Device PID: $device_pid | Role: $role | Secondary: $is_secondary | I3c_target: $is_i3c_target"
			setup_i3c_busowner_device "$bus_num" "$is_i3c_target"
		done < <(parse_i3c_busowner_devices)
		echo "DEBUG: Finished processing devices"
	else
		echo "DEBUG: MCTP_I3C is not true (value: $MCTP_I3C)"
	fi
	
else
	echo "DEBUG: Reset marker file exists at /tmp/.mctp_reset_done"
fi

touch /tmp/.mctp_reset_done

# Get the current host state
HOST_STATE=$(busctl get-property "$(mapper get-service /xyz/openbmc_project/state/host0)" \
    /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.Host CurrentHostState)

# Check if the host is already running
if [[ "$HOST_STATE" == *"xyz.openbmc_project.State.Host.HostState.Running"* ]]; then
    log "Host is running, start mctp-ctrl."

else
    log "Host is not running, waiting for state change..."
    if [[ "$MCTP_I2C" = "true" ]]; then        
        mctp_i2c_hotplug
        if [[ "$MCTP_I2C_ARP_MODE" = "true" ]]; then
            mctp_i2c_arp
        fi
    fi

fi

if [[ "$MCTP_I3C" = "true" ]]; then   
	log "MCTP_I3C is enabled, checking rescan status..."
	if [ ! -f /tmp/.mctp_i3c_rescan_done ]; then
		log "No marker file found, starting I3C rescan..."
		rescan_ok=true
		rescan_exhausted=false
		device_data=$(parse_i3c_busowner_devices)

		for bus in $(echo "$device_data" | awk -F'|' '{print $2}' | sort -u); do
			# Skip buses where no device has is_i3c_target=true
			echo "$device_data" | awk -F'|' -v b="$bus" '$2==b && $7=="true"{found=1} END{exit !found}' || continue

			pmasks=$(echo "$device_data"       | awk -F'|' -v b="$bus" '$2==b {printf "%s%s", sep, $3; sep="|"}')
			pids=$(echo "$device_data"         | awk -F'|' -v b="$bus" '$2==b {printf "%s%s", sep, $4; sep="|"}')
			roles=$(echo "$device_data"        | awk -F'|' -v b="$bus" '$2==b {printf "%s%s", sep, $5; sep="|"}')
			secondaries=$(echo "$device_data"  | awk -F'|' -v b="$bus" '$2==b {printf "%s%s", sep, $6; sep="|"}')
			i3c_targets=$(echo "$device_data"  | awk -F'|' -v b="$bus" '$2==b {printf "%s%s", sep, $7; sep="|"}')

			log "Rescanning bus $bus | PID Masks: $pmasks | Device PIDs: $pids | Roles: $roles | Secondaries: $secondaries | I3C Targets: $i3c_targets"
			mctp_i3c_rescan "$bus" "$pmasks" "$pids" "$roles" "$secondaries" "$i3c_targets"
			rc=$?
			if [ $rc -eq 0 ]; then
				log "Rescan successful for bus $bus"
			else
				log "Warning: Rescan failed for bus $bus (rc=$rc)  marking done to avoid infinite retry"
				rescan_ok=false
				rescan_exhausted=true
			fi
		done

		if $rescan_ok || $rescan_exhausted; then
			touch /tmp/.mctp_i3c_rescan_done
			if $rescan_ok; then
				log "I3C rescan completed successfully"
			else
				log "I3C rescan exhausted all attempts marker created to avoid infinite retry"
			fi
		fi
	else
		log "I3C rescan already completed successfully, skipping..."
	fi
fi

if [[ "$MCTP_PCIE" = "true" ]]; then
	if [[ "$MCTP_PCIE_ROLE" = "bus-owner" ]]; then
		log "Setting up PCIe bus owner device..."
		busctl call "$SERVICE" \
		  "$BASE_PATH/interfaces/mctppci0" \
		  "$BUSOWNER_IFACE" \
		  SetupEndpoint ay 3 0x3 0x00 0x00 || log "Warning: PCIe setup failed"
	fi
fi  
 
if [[ "$MCTP_I2C" = "true" ]]; then        
	log "Performing I2C hotplug..."
	mctp_i2c_hotplug
	
	if [[ "$MCTP_I2C_ARP_MODE" = "true" ]]; then        
		log "Performing I2C ARP discovery..."
		mctp_i2c_arp
	fi
fi

if [[ "$MCTP_USB" = "true" ]]; then
	log "Setting up USB MCTP endpoints..."
	for dev in $(mctp link show | awk '/mctpusb/{print $2}' | sed 's/://'); do
		log "Calling SetupEndpoint on $dev..."
		busctl call "$SERVICE" \
		  "$BASE_PATH/interfaces/$dev" \
		  "$BUSOWNER_IFACE" \
		  SetupEndpoint ay 1 0x00 || log "Warning: USB SetupEndpoint failed on $dev"
	done
fi


log "Retrieving MCTP routing table..."
mctp_get_routing_table

log "Device discovery completed, stabilizing..."
# Wait for output to flush before restarting
# sleep 30

exit 0

