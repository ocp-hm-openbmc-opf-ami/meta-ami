#!/bin/bash
# MCTP I2C ARP Library
# Can be sourced or executed directly

# Function to check if a bus has been processed by ARP
is_bus_arp_processed() {
    local check_bus=$1
    local arp_bus_file="/tmp/mctp-i2c-arp-bus"
    
    # If file doesn't exist, no buses have been processed
    if [[ ! -f "$arp_bus_file" ]]; then
        return 1  # Bus not processed
    fi
    
    # Check if bus number exists in file
    if grep -q "^${check_bus}$" "$arp_bus_file" 2>/dev/null; then
        return 0  # Bus already processed
    fi
    
    return 1  # Bus not processed
}

# Function to mark a bus as ARP processed
mark_bus_arp_processed() {
    local bus_num=$1
    local arp_bus_file="/tmp/mctp-i2c-arp-bus"
    
    # Append bus number to file (one per line)
    echo "$bus_num" >> "$arp_bus_file"
}

mctp_i2c_arp() {

MCTP_I2C_NET="${MCTP_I2C_NET:=1}"

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
" 2>/dev/null)"
fi

# --- Configuration ---
local SERVICE="au.com.codeconstruct.MCTP1"
local BASE_PATH="/au/com/codeconstruct/mctp1"
local DEFAULT_ADDR="0x61"
local ADDR_STORAGE="/tmp/mctp_next_addr"
local START_ADDR=19
local MIN_BUS_NUM=16
local DEV
local BUS_NUM
local CURRENT_DEC
local NEW_ADDR_HEX

# --- Forbidden Addresses ---
local FORBIDDEN=("00" "01" "02" "03" "04" "05" "06" "07" "30" "3c" "50" "61" "78" "79" "7a" "7b" "7c" "7d" "7e" "7f")

# Check if MCTP service exists
if ! busctl list | grep -q "$SERVICE"; then
    echo "Error: D-Bus service $SERVICE not found"
    return 1
fi

is_forbidden() {
  local check_hex=$1
  for addr in "${FORBIDDEN[@]}"; do
    if [[ "$check_hex" == "$addr" ]]; then return 0; fi
  done
  return 1
}

echo -e "\n=== Phase 3: Dynamic Assignment (17-byte UDID / 18th Byte Shifted) ==="

# Get list of I2C buses to scan
I2C_BUSES=$(mctp link show | grep "mctpi2c" | awk '{print $2}' | sed 's/://')

if [ -z "$I2C_BUSES" ]; then
    echo "  [INFO] No mctpi2c interfaces found."
    return 0
fi

echo "$I2C_BUSES" | while read -r DEV; do
  BUS_NUM=$(echo "$DEV" | sed 's/mctpi2c//')
  
  echo "  [Checking] Bus $BUS_NUM..."
  
  # Check if this bus has already been processed by ARP
  if is_bus_arp_processed "$BUS_NUM"; then
    echo "  [SKIP] Bus $BUS_NUM already processed by ARP"
    continue
  fi

  # Check if device exists at default address
  echo "  [Scanning] Bus $BUS_NUM for device at $DEFAULT_ADDR..."
  if ! timeout 2 i2cdetect -y "$BUS_NUM" "$DEFAULT_ADDR" "$DEFAULT_ADDR" 2>/dev/null | grep -q "61"; then
    echo "  [SKIP] No device at $DEFAULT_ADDR on bus $BUS_NUM"
    continue
  fi
  
  echo "  [FOUND] Device at $DEFAULT_ADDR on bus $BUS_NUM, starting ARP..."
  if true; then
    [ ! -f "$ADDR_STORAGE" ] && echo "$START_ADDR" > "$ADDR_STORAGE"
    CURRENT_DEC=$(cat "$ADDR_STORAGE")
    
    # 1. Find next safe target 7-bit address
    while true; do
      NEW_ADDR_HEX=$(printf "%02x" "$CURRENT_DEC")
      if is_forbidden "$NEW_ADDR_HEX"; then
        CURRENT_DEC=$((CURRENT_DEC + 1))
      else
        break
      fi
    done

    # 2. Send prepare commands
    if ! i2cset -y "$BUS_NUM" "$DEFAULT_ADDR" 0x01 cp 2>/dev/null; then
      continue
    fi
    
    if ! i2cset -y "$BUS_NUM" "$DEFAULT_ADDR" 0x02 cp 2>/dev/null; then
      continue
    fi

    # 3. Read 19 bytes (1-17: UDID, 18: Shifted Addr)
    RAW_DATA=$(i2ctransfer -y "$BUS_NUM" w1@"$DEFAULT_ADDR" 0x03 r19 2>&1)
    
    # Check if read was successful
    if [[ -z "$RAW_DATA" ]] || [[ "$RAW_DATA" == *"Error"* ]] || [[ "$RAW_DATA" == *"failed"* ]]; then
        continue
    fi
    
    # Extract 17-byte UDID (Bytes 1 through 17) - i2ctransfer already outputs with 0x prefix
    UDID_ORIGINAL=$(echo "$RAW_DATA" | awk '{for(i=1;i<=17;i++) if($i != "") printf "%s ", $i}')
    
    # Verify UDID_ORIGINAL is not empty or malformed
    UDID_COUNT=$(echo "$UDID_ORIGINAL" | wc -w)
    if [ "$UDID_COUNT" -ne 17 ]; then
        continue
    fi
    
    echo "  [BUS $BUS_NUM] UDID: $UDID_ORIGINAL" 
    
    # 3. Prepare Shifted Target Address for Write
    VAL_NEW=$(( 0x$NEW_ADDR_HEX ))
    WRITE_ADDR_VAL=$(( VAL_NEW << 1 | 1 ))
    WRITE_ADDR_HEX=$(printf "0x%02x" "$WRITE_ADDR_VAL")

    # 4. Prepare Shifted Target Address for Write
    VAL_NEW=$(( 0x$NEW_ADDR_HEX ))
    WRITE_ADDR_VAL=$(( VAL_NEW << 1 | 1 ))
    WRITE_ADDR_HEX=$(printf "0x%02x" "$WRITE_ADDR_VAL")

    # Remove first byte from UDID for i2cset command
    UDID_FOR_SET=$(echo "$UDID_ORIGINAL" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i}')
    
    # 5. Assign Address (Command 0x04 + 17-byte UDID + 1-byte Shifted Addr)
    if ! i2cset -y "$BUS_NUM" "$DEFAULT_ADDR" 0x04 $(printf '%s' "$UDID_FOR_SET" | tr -d '\r\n') "$WRITE_ADDR_HEX" sp 2>/dev/null; then
      continue
    fi

    sleep 0.1

    # 6. Post-Assignment Verification (Direct UDID Read)
    echo "  [BUS $BUS_NUM] Verifying at 0x$NEW_ADDR_HEX..."
    NEW_DATA=$(i2ctransfer -y "$BUS_NUM" w1@"$DEFAULT_ADDR" "$WRITE_ADDR_HEX" r19 2>&1)
    
    if [[ -z "$NEW_DATA" ]] || [[ "$NEW_DATA" == *"Error"* ]] || [[ "$NEW_DATA" == *"failed"* ]]; then
      continue
    fi

    # Extract UDID (1-17) and 18th byte for comparison
    UDID_VERIFY=$(echo "$NEW_DATA" | awk '{for(i=1;i<=17;i++) if($i != "") printf "%s ", $i}')
    BYTE_18_READ=$(echo "$NEW_DATA" | awk '{print $18}')

    # 7. Final Comparison
    if [ "$UDID_ORIGINAL" == "$UDID_VERIFY" ] && [ "$BYTE_18_READ" == "$WRITE_ADDR_HEX" ]; then
      
      # 8. Setup MCTP link and address before AssignEndpoint
      mctp link set mctpi2c$BUS_NUM net $MCTP_I2C_NET up mtu 68
      mctp addr add 0x20 dev mctpi2c$BUS_NUM 2>/dev/null || echo "  [INFO] Address 0x20 already exists on mctpi2c$BUS_NUM"
      
      # 9. Call AssignEndpoint
      if busctl call "$SERVICE" "$BASE_PATH/interfaces/$DEV" au.com.codeconstruct.MCTP.BusOwner1 \
        AssignEndpoint ay 1 "0x$NEW_ADDR_HEX" 2>/dev/null; then
        
        echo $((CURRENT_DEC + 1)) > "$ADDR_STORAGE"
        
        # Mark this bus as successfully processed by ARP
        mark_bus_arp_processed "$BUS_NUM"
      else
        continue
      fi
    else
      continue
    fi
  fi
done

}

# If script is executed directly (not sourced), run the main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    mctp_i2c_arp "$@"
fi
