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
        echo "Required services for the BMC readiness are in active state."
        exit 0
    fi
    ((IPMI_ATTEMPTS++))
    sleep "$INTERVAL"
done

echo "Some required services failed to become active after $RETRY_COUNT attempts."
exit 1
