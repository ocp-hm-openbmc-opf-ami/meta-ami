
#!/bin/sh
# cleanup-bmc.sh — remove BMC image artifacts from INITRAMFS_DIR
# Usage: cleanup-bmc.sh
# Notes:
#   - Removes base and `alt` variants of the image files.
#   - Works under /bin/sh (busybox/dash/ash) and tolerates missing fwupd helpers.

set -eu

# Optional helpers (logging, section, wait_for_log_sync). Continue if missing.
. /usr/libexec/fwupd/common.sh 2>/dev/null || true

INITRAMFS_DIR="${INITRAMFS_DIR:-/run/initramfs}"

cleanup_overlay_with_blacklist_and_rsync() {

    # Arguments: RWFS_MOUNT RWFS_OVERLAY RWFS_MTD OVERLAY PERSISTENT
    RWFS_MOUNT="$1"
    RWFS_OVERLAY="$2"
    RWFS_MTD="$3"
    OVERLAY="$4"
    PERSISTENT="$5"
    EMMC_FILE_LIST=("/etc/extlog/extended.log*" "/etc/extlog/phosphor-logging/errors/" "/etc/extlog/phosphor-logging/ipmi/errors/" "/etc/extlog/phosphor-logging/raid/errors/" "/etc/extlog/phosphor-logging/ipmi_rollover_backup/")

    debug_log "Entered cleanup_overlay_with_blacklist_and_rsync() (blacklist/rsync mode)"

    if [ "$PERSISTENT" = "0" ]; then
    touch /etc/sync-enable || true
    touch /etc/nv-sync-enable || true
        # Mount RWFS manually if not mounted
        if ! mountpoint -q "$RWFS_MOUNT"; then
            debug_log "$RWFS_MOUNT not mounted, attempting manual mount."
            mkdir -p "$RWFS_MOUNT"
            mount -t jffs2 -o rw "$RWFS_MTD" "$RWFS_MOUNT" || true
        fi

        # Create overlay directory if missing
        if [ ! -d "$RWFS_OVERLAY" ]; then
            debug_log "Creating overlay directory: $RWFS_OVERLAY"
            mkdir -p "$RWFS_OVERLAY"
        fi
        # Rsync overlay to RWFS_OVERLAY (volatile case)
        debug_log "Syncing $OVERLAY to $RWFS_OVERLAY via rsync"
        rsync -a --inplace --partial --delete "$OVERLAY/" "$RWFS_OVERLAY/" || true
        sync "$RWFS_OVERLAY" || true
        log "Volatile overlay rsync complete: $OVERLAY -> $RWFS_OVERLAY"
    fi

    # Remove files listed in /tmp/blacklist from overlay (always)
    BLACKLIST="/tmp/blacklist"
    if [ -s "$BLACKLIST" ]; then
        log "Deleting files from blacklist: $BLACKLIST"
        while IFS= read -r file; do
            [ -n "$file" ] || continue
            target="$RWFS_OVERLAY$file"
            debug_log "Deleting: $target"
            rm -rf -- "$target" 2>/dev/null || true
        done < "$BLACKLIST"
        # remove files if present in emmc
        for emmc_list in "${EMMC_FILE_LIST[@]}"; do
            if grep -q -- "$emmc_list" "$BLACKLIST"; then
                rm -rf -- "$emmc_list" 2>/dev/null || true
            fi
        done
    else
        debug_log "No blacklist file found or empty: $BLACKLIST"
    fi

    log "Overlay cleanup complete (rsync + blacklist applied)"
    debug_log "Overlay cleanup complete (rsync + blacklist applied)"
}


restore_uboot_env_data() {
    # Initialize locals
    mtd_part=""
    : "${uboot_env_bin_file:=u-boot-env.bin}"
    : "${UBOOT_ENV_STAGED:=/tmp/${uboot_env_bin_file}}"
    if [ ! -s "$UBOOT_ENV_STAGED" ]; then
        log "BMC Full Flash - staged U-Boot env not found or empty: ${UBOOT_ENV_STAGED}"
        command -v redfish_log_abort >/dev/null 2>&1 && redfish_log_abort "BMC Full Flash - restore u-boot-env failed (staged file missing)" || true
        return 1
    fi
    if command -v get_mtd_by_label >/dev/null 2>&1; then
        mtd_part="$(get_mtd_by_label 'u-boot-env' 2>/dev/null || true)"
    else
        mtd_part="$(awk -F: 'tolower($2) ~ /"'"'u-boot-env'"'"$/ {gsub(/^\s+|\s+$/, "", $1); print $1}' /proc/mtd 2>/dev/null || true)"
    fi
    if [ -z "$mtd_part" ] || [ ! -e "/dev/$mtd_part" ]; then
        log "BMC Full Flash - u-boot-env MTD partition not found"
        command -v redfish_log_abort >/dev/null 2>&1 && redfish_log_abort "BMC Full Flash - restore u-boot-env failed (mtd missing)" || true
        return 1
    fi
    log "Restoring U-Boot env to /dev/${mtd_part} from ${UBOOT_ENV_STAGED}"
    if command -v mtd-util >/dev/null 2>&1; then
        if ! mtd-util -d "/dev/${mtd_part}" c "${UBOOT_ENV_STAGED}" 0; then
            log "BMC Full Flash - restore u-boot-env partition failed with mtd-util, trying flashcp..."
            if command -v flashcp >/dev/null 2>&1; then
                if ! flashcp "${UBOOT_ENV_STAGED}" "/dev/${mtd_part}"; then
                    log "BMC Full Flash - restore u-boot-env partition failed with both mtd-util and flashcp"
                    command -v redfish_log_abort >/dev/null 2>&1 && redfish_log_abort "BMC Full Flash - restore u-boot-env partition failed (both mtd-util and flashcp)" || true
                    return 1
                else
                    log "U-Boot env restore successful with flashcp (/dev/${mtd_part})"
                fi
            else
                log "BMC Full Flash - flashcp not found in PATH"
                command -v redfish_log_abort >/dev/null 2>&1 && redfish_log_abort "BMC Full Flash - restore u-boot-env failed (flashcp missing)" || true
                return 127
            fi
        else
            log "U-Boot env restore successful (/dev/${mtd_part})"
        fi
    elif command -v flashcp >/dev/null 2>&1; then
        if ! flashcp "${UBOOT_ENV_STAGED}" "/dev/${mtd_part}"; then
            log "BMC Full Flash - restore u-boot-env partition failed with flashcp"
            command -v redfish_log_abort >/dev/null 2>&1 && redfish_log_abort "BMC Full Flash - restore u-boot-env partition failed (flashcp)" || true
            return 1
        else
            log "U-Boot env restore successful with flashcp (/dev/${mtd_part})"
        fi
    else
        log "BMC Full Flash - neither mtd-util nor flashcp found in PATH"
        command -v redfish_log_abort >/dev/null 2>&1 && redfish_log_abort "BMC Full Flash - restore u-boot-env failed (no mtd-util or flashcp)" || true
        return 127
    fi
}

main() {
    debug_log "Entered main()"
    base=""  # loop variable initialization (harmless; prevents set -u complaints if reused)

    # Optional U-Boot env restore (policy decided during prepare stage)
    if [ "${IS_UBOOT_ENABLED:-false}" = "true" ]; then
        log "IS_UBOOT_ENABLED is true; restoring U-Boot env"
        restore_uboot_env_data || log "WARNING: U-Boot environment restore failed"
    fi

    # Detect rwfs device type: mmcblk (persistent) or mtd (volatile)
    RWFS_DEV=""
    RWFS_MOUNT=""
    RWFS_OVERLAY=""
    RWFS_MTD=""
    OVERLAY=""
    PERSISTENT=0

    # Find rwfs mount point
    if [ -d "$INITRAMFS_DIR" ]; then
        RWFS_MOUNT="/run/initramfs/rw"
        debug_log "INITRAMFS_DIR present, set RWFS_MOUNT to $RWFS_MOUNT"
    else
        RWFS_MOUNT="/tmp/.rwfs"
        debug_log "INITRAMFS_DIR not present, set RWFS_MOUNT to $RWFS_MOUNT"
    fi

    if [ -n "$RWFS_MOUNT" ]; then
        RWFS_BACK_DEV=$(awk -v mnt="$RWFS_MOUNT" '$2==mnt {print $1}' /proc/mounts)
        debug_log "RWFS_BACK_DEV detected as $RWFS_BACK_DEV"
        case "$RWFS_BACK_DEV" in
            /dev/mmcblk*)
                RWFS_DEV="mmcblk"
                RWFS_MOUNT="/run/initramfs/rw"
                RWFS_OVERLAY="/run/initramfs/rw/cow"
                RWFS_MTD="$RWFS_BACK_DEV"
                OVERLAY="/run/initramfs/rw/cow"
                PERSISTENT=1
                log "Detected rwfs device type: mmcblk (persistent) (mount: $RWFS_MOUNT, dev: $RWFS_BACK_DEV)"
                debug_log "mmcblk: RWFS_OVERLAY=$RWFS_OVERLAY, RWFS_MTD=$RWFS_MTD, OVERLAY=$OVERLAY, PERSISTENT=$PERSISTENT"
                ;;
            *mtd*)
                RWFS_DEV="mtd"
                if [ -d "$INITRAMFS_DIR" ]; then
                    RWFS_MOUNT="/tmp/.rwfs"
                    RWFS_OVERLAY="/tmp/.rwfs/cow"
                    RWFS_MTD="$RWFS_BACK_DEV"
                    OVERLAY="/run/initramfs/rw/cow"
                    PERSISTENT=0
                else
                    RWFS_MOUNT="/tmp/.rwfs"
                    RWFS_OVERLAY="/tmp/.rwfs/.overlay"
                    RWFS_MTD="$RWFS_BACK_DEV"
                    OVERLAY="/tmp/.overlay"
                    PERSISTENT=0
                fi
                log "Detected rwfs device type: mtd (volatile) (mount: $RWFS_MOUNT, dev: $RWFS_BACK_DEV)"
                debug_log "mtd: RWFS_OVERLAY=$RWFS_OVERLAY, RWFS_MTD=$RWFS_MTD, OVERLAY=$OVERLAY, PERSISTENT=$PERSISTENT"
                umount "$RWFS_MOUNT" || true
                ;;
            *)
                log "rwfs mount $RWFS_MOUNT has unknown backing device: $RWFS_BACK_DEV"
                debug_log "Searching for mtd partition in /proc/mtd"
                mtd_part=$(awk -F'"' '$2=="rwfs" { split($1,a,":"); gsub(/[[:space:]]/,"",a[1]); sub(/^mtd/, "", a[1]); print a[1] }' /proc/mtd)
                if [ -n "$mtd_part" ] && [ -e "/dev/mtdblock$mtd_part" ]; then
                    log "Found mtd partition: $mtd_part, attempting to mount as jffs2 to /tmp/.rwfs"
                    if [ -d "$INITRAMFS_DIR" ]; then
                        RWFS_BACK_DEV="/dev/mtdblock$mtd_part"
                        RWFS_DEV="mtd"
                        RWFS_MOUNT="/tmp/.rwfs"
                        RWFS_OVERLAY="/tmp/.rwfs/cow"
                        RWFS_MTD="$RWFS_BACK_DEV"
                        OVERLAY="/run/initramfs/rw/cow"
                        PERSISTENT=0
                    else
                        RWFS_BACK_DEV="/dev/mtdblock$mtd_part"
                        RWFS_DEV="mtd"
                        RWFS_MOUNT="/tmp/.rwfs"
                        RWFS_OVERLAY="/tmp/.rwfs/.overlay"
                        RWFS_MTD="mtd:rwfs"
                        OVERLAY="/tmp/.overlay"
                        PERSISTENT=0
                    fi

                    debug_log "mtd: RWFS_OVERLAY=$RWFS_OVERLAY, RWFS_MTD=$RWFS_MTD, OVERLAY=$OVERLAY, PERSISTENT=$PERSISTENT"
                    umount "$RWFS_MOUNT" || true
                else
                    log "No suitable mtd partition found in /proc/mtd"
                fi
                ;;
        esac
    fi

    log "Calling cleanup_overlay_with_blacklist_and_rsync with:"
    debug_log "RWFS_MOUNT=$RWFS_MOUNT RWFS_OVERLAY=$RWFS_OVERLAY RWFS_MTD=$RWFS_MTD OVERLAY=$OVERLAY PERSISTENT=$PERSISTENT"
    cleanup_overlay_with_blacklist_and_rsync "$RWFS_MOUNT" "$RWFS_OVERLAY" "$RWFS_MTD" "$OVERLAY" "$PERSISTENT"
    _start_if_inactive xyz.openbmc_project.Software.Sync.service || true
    command -v wait_for_log_sync >/dev/null 2>&1 && wait_for_log_sync || true
    debug_log "wait_for_log_sync called"
    
    exit 0
}

main "$@"
