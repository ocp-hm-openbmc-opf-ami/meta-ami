#!/bin/bash
# MCTP Get Routing Table Library
# Can be sourced or executed directly

mctp_get_routing_table() {

# --- Configuration ---
local SERVICE="au.com.codeconstruct.MCTP1"
local INTERFACE="au.com.codeconstruct.MCTP.Bridge1"
local BASE_PATH="/au/com/codeconstruct/mctp1"
local obj_path

echo "=== MCTP Bridge Objects ==="
echo "Service: $SERVICE"
echo "Interface: $INTERFACE"
echo ""

# Check if service exists
if ! busctl list | grep -q "$SERVICE"; then
    echo "Error: Service $SERVICE not found on D-Bus"
    return 1
fi

# Get all object paths under the base path
echo "Scanning for MCTP bridge objects..."
obj_paths=$(busctl tree "$SERVICE" --list 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$obj_paths" ]; then
    echo "Warning: No objects found or failed to enumerate objects"
    return 1
fi

# Process each object path
echo "$obj_paths" | while IFS= read -r obj_path; do
    [ -z "$obj_path" ] && continue

    # Check if this object has the Bridge1 interface
    if busctl introspect "$SERVICE" "$obj_path" 2>/dev/null | grep -q "$INTERFACE"; then
        echo "Found bridge: $obj_path"
        echo "Getting routing table..."
        busctl call "$SERVICE" "$obj_path" "$INTERFACE" GetRoutingTable 2>/dev/null || {
            echo "Warning: Failed to get routing table from $obj_path"
        }
    fi
done

}

# If script is executed directly (not sourced), run the main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    mctp_get_routing_table "$@"
fi
