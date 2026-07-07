#!/bin/bash
# MCTP I2C Hotplug Library
# Can be sourced or executed directly

mctp_i2c_hotplug() {

# --- Configuration ---
MCTP_I2C_ARP_MODE="${MCTP_I2C_ARP_MODE:=false}"
MCTP_I2C_NET="${MCTP_I2C_NET:=1}"

# Whitelist: only scan these addresses (space-separated hex, e.g., "32 13 3c")
# Leave empty to scan all addresses found by i2cdetect
local MCTP_WHITELIST="${MCTP_WHITELIST:=12 13 1d 32}"

# Read settings from mctp_ext_options.json if available
local MCTP_EXT_CONF="${MCTP_EXT_CONF:-/usr/share/mctp/mctp_ext_options.json}"
if [ -f "$MCTP_EXT_CONF" ]; then
	eval "$(python3 -c "
import json
with open('$MCTP_EXT_CONF') as f:
    data = json.load(f)
for item in data:
    for exp in item.get('Exposes', []):
        if exp.get('Type') != 'MCTPI2CConfiguration':
            continue
        net = exp.get('Net', '')
        if net:
            print(f'MCTP_I2C_NET={net}')
        arp = exp.get('ArpEnabled', '')
        if arp == 'enabled':
            print('MCTP_I2C_ARP_MODE=true')
        elif arp == 'disabled':
            print('MCTP_I2C_ARP_MODE=false')
        wl = exp.get('Whitelist', [])
        if wl:
            print('MCTP_WHITELIST=\"' + ' '.join(wl) + '\"')
" 2>/dev/null)"
fi

local SERVICE="au.com.codeconstruct.MCTP1"
local BASE_PATH="/au/com/codeconstruct/mctp1"
local BUSOWNER_IFACE="au.com.codeconstruct.MCTP.BusOwner1"
local ENDPOINT_IFACE="au.com.codeconstruct.MCTP.Endpoint1"
local MIN_BUS_NUM=16
local DEV
local BUS_NUM
local EID
local PHYS
local HEX_ADDR

# --- Forbidden Addresses ---
local FORBIDDEN=("1" "2" "3" "4" "5" "6" "7" "8" "9" "a" "b" "c" "d" "e" "f" "00" "01" "02" "03" "04" "05" "06" "07" "30" "3c" "50" "61" "78" "79" "7a" "7b" "7c" "7d" "7e" "7f")

# Check if MCTP service exists
if ! busctl list | grep -q "$SERVICE"; then
    echo "Error: D-Bus service $SERVICE not found"
    return 1
fi

# --- Helper Functions ---
is_forbidden() {
  local check_hex=$1
  for addr in "${FORBIDDEN[@]}"; do
    if [[ "$check_hex" == "$addr" ]]; then return 0; fi
  done
  return 1
}

# Check if address is in whitelist (if whitelist is configured)
is_in_whitelist() {
  local check_hex=$1
  
  # If whitelist is empty, allow all addresses
  if [[ -z "$MCTP_WHITELIST" ]]; then
    return 0
  fi
  
  # Check if address is in whitelist
  for addr in $MCTP_WHITELIST; do
    if [[ "$check_hex" == "$addr" ]]; then
      return 0
    fi
  done
  return 1
}

check_device_exists() {
  local addr="0x$1"
  mctp neigh show | grep -q "address $addr"
}

# Check if device with specific bus and address exists in D-Bus
is_device_exists() {
  local check_bus=$1
  local check_addr=$2  # hex format like "3c"
  
  # Convert hex address to decimal for comparison
  local check_addr_dec=$((16#$check_addr))
  
  # Get all endpoint paths from network 1
  local endpoints=$(busctl tree "$SERVICE" 2>/dev/null | grep "$BASE_PATH/networks/1/endpoints" | awk '{print $1}')
  
  for endpoint in $endpoints; do
    # Get Bus and Address properties
    local bus_num=$(busctl get-property "$SERVICE" "$endpoint" \
      xyz.openbmc_project.Inventory.Decorator.I2CDevice Bus 2>/dev/null | awk '{print $2}')
    local addr_dec=$(busctl get-property "$SERVICE" "$endpoint" \
      xyz.openbmc_project.Inventory.Decorator.I2CDevice Address 2>/dev/null | awk '{print $2}')
    
    # Check if both bus and address match
    if [[ "$bus_num" == "$check_bus" ]] && [[ "$addr_dec" == "$check_addr_dec" ]]; then
      return 0  # Device exists
    fi
  done
  return 1  # Device not found
}

# --- Phase 1: Route Validation ---
echo "=== Phase 1: Validating Existing Routes ==="
mctp neigh show | grep "mctpi2c" | while read -r line; do
  EID=$(echo "$line" | awk '{print $2}')
  DEV=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}')
  PHYS=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i=="lladdr") print $(i+1)}')
  [ -z "$PHYS" ] && continue
  HEX_ADDR=$(echo "$PHYS" | sed 's/0x//')

  bus=${DEV#mctpi2c}
  # Check if address responds (probe specific addr)
  detect_output=$(i2cdetect -y $bus $PHYS $PHYS 2>&1)
  if echo "$detect_output" | grep -q ": --"; then
      echo "No response at $PHYS on bus $bus (stale endpoint)"

      # Remove endpoint via D-Bus
      ep_path="$BASE_PATH/networks/$MCTP_I2C_NET/endpoints/$EID"
      remove_output=$(busctl call $SERVICE $ep_path $ENDPOINT_IFACE Remove 2>&1)
      if [ $? -eq 0 ]; then
          echo "Successfully removed EID $EID (path: $ep_path)"
      else
          echo "Failed to remove EID $EID: $remove_output"
      fi
  else
      echo "Address $PHYS responds on bus $bus (active)"
      if ! busctl introspect "$SERVICE" "$BASE_PATH/networks/$MCTP_I2C_NET/endpoints/$EID" > /dev/null 2>&1; then
        echo "[!] Syncing EID $EID via AssignEndpointStatic..."
        busctl call "$SERVICE" "$BASE_PATH/interfaces/$DEV" "$BUSOWNER_IFACE" \
          AssignEndpointStatic ayy 1 0x$HEX_ADDR $EID   
      fi
  fi
 
done

# --- Phase 2: Static Neighbor Discovery (Buses >= 16) ---
if [[ "$MCTP_I2C_ARP_MODE" = "false" ]]; then
echo -e "\n=== Phase 2: Scanning I2C Links (Buses >= $MIN_BUS_NUM) ==="

mctp link show | grep "mctpi2c" | awk '{print $2}' | sed 's/://' | while read -r DEV; do
  BUS_NUM=$(echo "$DEV" | sed 's/mctpi2c//')
  if [ "$BUS_NUM" -lt "$MIN_BUS_NUM" ]; then continue; fi

  for HEX_ADDR in $(i2cdetect -y "$BUS_NUM" 0x08 0x77 | grep -v '0 1 2 3' | awk '{for(i=2;i<=NF;i++) if($i != "--" && $i != "UU") print $i}'); do
    if is_forbidden "$HEX_ADDR" || check_device_exists "$HEX_ADDR"; then continue; fi
    
    # Check whitelist
    if ! is_in_whitelist "$HEX_ADDR"; then
      echo "  [SKIP] Device at 0x$HEX_ADDR not in whitelist"
      continue
    fi
    
    # Check if device with this exact bus+address already exists in D-Bus
    if is_device_exists "$BUS_NUM" "$HEX_ADDR"; then
      echo "  [SKIP] Device at 0x$HEX_ADDR on bus $BUS_NUM already exists in D-Bus"
      continue
    fi
    
    echo "  [+] New device at 0x$HEX_ADDR on $DEV. Assigning..."
    busctl call "$SERVICE" "$BASE_PATH/interfaces/$DEV" "$BUSOWNER_IFACE" AssignEndpoint ay 1 "0x$HEX_ADDR"
  done
done
fi

}

# If script is executed directly (not sourced), run the main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    mctp_i2c_hotplug "$@"
fi
