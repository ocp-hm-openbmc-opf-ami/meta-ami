#!/bin/sh
# Reset auto-recovery U-Boot flags after successful Linux boot.

set -e

LOG_TAG="bmc-auto-recovery"

log_info() {
    logger -t "${LOG_TAG}" "$1"
    echo "[INFO] $1"
}

set_recovery_defaults() {
    fw_setenv recovery_current_bootretry 0
    fw_setenv recovery_mode_selection auto
}

log_info "BMC boot complete - resetting recovery env variables"
set_recovery_defaults

log_info "bmc-auto-recovery boot handler complete"
exit 0
