#!/bin/bash

source /etc/bmc-services-ready.conf

attempt=0
while [ $attempt -lt $RETRY_COUNT ]; do
    all_active=true
    for service in "${SERVICES[@]}"; do
        if ! systemctl is-active --quiet "$service"; then
            all_active=false
        fi
    done
    if $all_active; then
        break
    else
        ((attempt++))
        sleep "$INTERVAL"
    fi
done

if [ $attempt -eq $RETRY_COUNT ]; then
    echo "Some required services failed to become active after $RETRY_COUNT attempts."
    exit 1
fi

IPMI_ATTEMPTS=0
IPMI_RETRY_COUNT=12
while [ $IPMI_ATTEMPTS -lt $IPMI_RETRY_COUNT ]; do
    if ipmitool raw 6 1 > /dev/null 2>&1; then
        break
    fi
    ((IPMI_ATTEMPTS++))
    sleep "$INTERVAL"
done

if [ $IPMI_ATTEMPTS -eq $IPMI_RETRY_COUNT ]; then
    echo "Local IPMI (Get Device ID) did not respond after $IPMI_RETRY_COUNT attempts."
    exit 1
fi

# Wait for the BMC UUID D-Bus interface (xyz.openbmc_project.Common.UUID) to be
# published so netipmid can build the RAKP-2 message for remote IPMI sessions.
# UUID_POLL_INTERVAL and UUID_TIMEOUT_SEC come from /etc/bmc-services-ready.conf.
UUID_ATTEMPTS=0
# Derive the poll count from the configured timeout and interval so the two stay
# consistent even if either value is retuned in bmc-services-ready.conf. awk is
# used for float-safe division (UUID_POLL_INTERVAL is fractional).
UUID_MAX_ATTEMPTS=$(awk "BEGIN {print int($UUID_TIMEOUT_SEC/$UUID_POLL_INTERVAL)}")
while [ $UUID_ATTEMPTS -lt $UUID_MAX_ATTEMPTS ]; do
    if busctl call xyz.openbmc_project.ObjectMapper \
            /xyz/openbmc_project/object_mapper \
            xyz.openbmc_project.ObjectMapper GetSubTree \
            sias / 0 1 xyz.openbmc_project.Common.UUID 2>/dev/null \
            | grep -q 'xyz.openbmc_project.Common.UUID'; then
        break
    fi
    ((UUID_ATTEMPTS++))
    sleep "$UUID_POLL_INTERVAL"
done

if [ $UUID_ATTEMPTS -eq $UUID_MAX_ATTEMPTS ]; then
    echo "BMC UUID D-Bus interface (Common.UUID) not exposed after ${UUID_TIMEOUT_SEC}s."
    exit 1
fi

echo "Required services for the BMC readiness are in active state."
exit 0
