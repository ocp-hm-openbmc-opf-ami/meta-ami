#!/bin/bash

VER=$(grep '^VERSION_ID=' /etc/os-release | sed 's/[^=]*=\([^-]*\)-.*/\1/')

log() {
    echo "$@"
}

FWTYPE=""
FWVER=""
PFMREV=""
UPDATE_PERCENT_INIT=0
UPDATE_PERCENT_FETCH_START=10
UPDATE_PERCENT_FETCH_COMPLETE=30
UPDATE_PERCENT_PRESTAGE_VERIFY_START=40
UPDATE_PERCENT_PRESTAGE_VERIFY_COMPLETE=50
UPDATE_PERCENT_FLASH_OR_STAGE_START=60
UPDATE_PERCENT_FLASH_OR_STAGE_COMPLETE=95
UPDATE_PERCENT_SUCCESS=100
UPDATE_PERCENT_FAIL=100
UPDATE_STATUS_STARTING=Starting
UPDATE_STATUS_RUNNING=Running
UPDATE_STATUS_COMPLETED=Completed
UPDATE_STATUS_CANCELLED=Cancelled
UPDATE_STATUS_EXCEPTION=Exception
evt=""
sev=""
msg=""
SECURE_BOOT_STRAP_ENABLED=1
update=/run/initramfs/update
SLOT_FILE=/run/media/slot
BMC_PRESERVE_DIR=/tmp/bmc_preserve_dir
TMP_OVERLAY=/tmp/.rwfs/.overlay
TMP_RWFS=/tmp/.rwfs
uboot_env_bin_file="uboot_env_data.bin"
preserve_bios="/tmp/preserveBIOS.json"
NON_INTEL_PLATFORMS_MODE=1
is_Uboot_enabled=false
immediate="xyz.openbmc_project.Software.ApplyTime.RequestedApplyTimes.Immediate"
atMaintenanceWindowStart="xyz.openbmc_project.Software.ApplyTime.RequestedApplyTimes.AtMaintenanceWindowStart"

#Check the type of firmware currently being updated
BMC_FW_UPDATING=1
OTHER_FW_UPDATING=2
RET_FAILED=1
RET_NORMAL=0

if test -x $update; then
    whitelist=/run/initramfs/whitelist
    is_intel_platform=false
else
    whitelist=/tmp/whitelist
    is_intel_platform=true
fi

update_percentage() {
    if [ -n "$img_obj" ]; then
        busctl set-property xyz.openbmc_project.Software.BMC.Updater \
               /xyz/openbmc_project/software/$img_obj \
               xyz.openbmc_project.Software.ActivationProgress Progress \
               y $1 || return 0
    fi
}

update_status() {
    if [ -n "$img_obj" ]; then
        busctl set-property xyz.openbmc_project.Software.BMC.Updater \
               /xyz/openbmc_project/software/$img_obj \
               xyz.openbmc_project.Common.Task Status \
               s xyz.openbmc_project.Common.Task.OperationStatus.$1 || return 0
    fi
}

get_firmware_version() {
    if [ -n "$img_obj" ]; then
        busctl get-property xyz.openbmc_project.Software.BMC.Updater \
               /xyz/openbmc_project/software/$img_obj \
               xyz.openbmc_project.Software.Version Version | awk -F'"' '{print $2}'
    fi
}

is_BMC_FW_updated() {
    local IS_BMC_FW_UPDATING=1
    #If BMC device is being updated with firmware, 
    #In this state, the BMC will no longer be allowed to execute other firmware updates. 
    local data_type Purpose_data
    local Purpose_value=$(busctl get-property xyz.openbmc_project.Software.BMC.Updater /xyz/openbmc_project/software/${1} xyz.openbmc_project.Software.Version Purpose)
    local Purpose=$(echo "$Purpose_value" | awk '{print $2}'| tr -d '"')
    if [ "${Purpose}" = "xyz.openbmc_project.Software.Version.VersionPurpose.BMC" ];then
        return ${IS_BMC_FW_UPDATING}
    fi
    return 0
    
}

Other_firmware_is_being_updated() {
    #Check_other_firmware_is_updating
    local objIds=$(busctl tree xyz.openbmc_project.Software.BMC.Updater | grep -oE '/xyz/openbmc_project/software/[0-9a-f_]+')
    while IFS= read -r line; do
        local objId=$(awk -F'/' '{print $5}' <<< "$line")
        if [ ${#objId} -gt 15 ] && [ "${1}" != "${objId}" ]; then
            local ret_Progress=$(busctl get-property xyz.openbmc_project.Software.BMC.Updater /xyz/openbmc_project/software/${objId} xyz.openbmc_project.Software.ActivationProgress Progress 2>/dev/null)
            local UpdateProgress=$(echo "$ret_Progress" | awk '{print $2}')

            if [ "${UpdateProgress}" = "100" ] || [ "${UpdateProgress}" = "" ]; then
                continue
            else
                #Other FW is updating
                local ret_Purpose=$(busctl get-property xyz.openbmc_project.Software.BMC.Updater /xyz/openbmc_project/software/${objId} xyz.openbmc_project.Software.Version Purpose)
                local Purpose=$(echo "$ret_Purpose" | awk '{print $2}'| tr -d '"')
                if [ "${Purpose}" = "xyz.openbmc_project.Software.Version.VersionPurpose.BMC" ]; then
                    return ${BMC_FW_UPDATING}
                else 
                    return ${OTHER_FW_UPDATING}
                fi
            fi
        fi
    done <<< "$objIds"
}

IsMeetsMultiFirmwareRules() {
    #Check if other firmware image is updating
    Other_firmware_is_being_updated ${1}
    local is_alread_fw_task_running=$?
    if [ "${is_alread_fw_task_running}" = "${BMC_FW_UPDATING}" ];then
        return ${RET_FAILED}
    elif [ "${is_alread_fw_task_running}" = "${OTHER_FW_UPDATING}" ];then
        #check if ${img_obj} is updated for bmc fw
        is_BMC_FW_updated ${1}
        if [ "$?" = "${BMC_FW_UPDATING}" ];then
            return ${RET_FAILED}
        fi
    fi
    return ${RET_NORMAL}
}

create_Phosphor_log() {
    # local evt=$1
    # local sev=$2
    # local msg=$3
    busctl call xyz.openbmc_project.Logging \
               /xyz/openbmc_project/logging \
               xyz.openbmc_project.Logging.Create Create \
               ssa{ss} "$msg" xyz.openbmc_project.Logging.Entry.Level.$sev 2 FirmwareType $FWTYPE Status "$evt"
}

check_preserv_config() {
    value=$(busctl get-property xyz.openbmc_project.Software.BMC.Updater \
            /xyz/openbmc_project/software \
            xyz.openbmc_project.Software.ApplyOptions ClearConfig \
            | awk '{print $2}' )
    if [ -n "$value" ]; then
        # Dont preserve if clearconfig is true
        if [ "$value" = "true" ]; then
            if test -x $update
            then
                truncate -s 0 "$whitelist"
            fi
            log "BMC Full Flash - Not Preserved the Config"
        else
            log "BMC Full Flash - Start Preserve Config"
            if [[ "$applytime" == "$immediate" || "$applytime" == "$atMaintenanceWindowStart"  ]];then
                #mount nv rwfs mtd partition
                mount -t jffs2 -o sync,ro mtd:rwfs $TMP_RWFS
                #start nv sync  
                systemctl start nv-sync.service
                #stop nv sync to dump overlay files to nv storage
                wait_for_log_sync
                systemctl stop nv-sync.service
            fi
            log "BMC Full Flash - Preserve Config Done"

            if [ "$1" = "$NON_INTEL_PLATFORMS_MODE" ];then
                log "BMC Full Flash - Backup u-boot-env partition"
                backup_uboot_env_data $1
            else
                log "BMC Full Flash - Restore u-boot-env partition"
                restore_uboot_env_data
            fi
        fi
    else
        log "ClearConfig is not available"
    fi
}

Check_and_update_whitelist() {
    service="xyz.openbmc_project.EntityManager"
    interface="xyz.openbmc_project.Configuration.Preserve"
    config_list=$(busctl tree --list $service | grep -o '.*Configuration/.*')

    if [ -f $whitelist ]; then
        truncate -s 0 "$whitelist"
    fi

    for config_obj in $config_list; do
        isEnable=$(busctl get-property $service $config_obj $interface isEnable | awk '{print $2}')
        filespath=$(busctl get-property $service $config_obj $interface filepath | awk -F'"' '{for(i=2;i<=NF;i+=2) print $i}')
        if [[ -n "$isEnable" && "$isEnable" = "true" ]]; then
            for file_path in $filespath; do
                echo $file_path >> $whitelist
            done

            if [ "${config_obj##*/}" == "U_BOOT_ENV" ]; then
                log "BMC Full Flash - Backup u-boot-env partition"
                backup_uboot_env_data
                is_Uboot_enabled=true
            fi
        fi
    done

    # Update preserve setting to default state
    for config_obj in $config_list; do
        isOptional=$(busctl get-property $service $config_obj $interface isOptional | awk '{print $2}')
        if [[ -n "$isOptional" && "$isOptional" = "true" && "${config_obj##*/}" != "U_BOOT_ENV" ]]; then
            busctl set-property $service $config_obj $interface isEnable b false
        fi
    done
}

Backup_bmc_config() {
    log "BMC Full Flash - Start Backup Configuration"

    if [[ "$applytime" == "$immediate" || "$applytime" == "$atMaintenanceWindowStart" ]]; then
	# Stop nv sync
	systemctl stop nv-sync.service
	# Unmount rwfs
	umount $TMP_RWFS
    fi

    while read -r f
    do
        # Entries shall start with /, no trailing /.. or embedded /../
        if test "/${f#/}" != "$f" -o "${f%/..}" != "${f#*/../}"
        then
            echo 1>&2 "WARNING: Skipping bad whitelist entry $f."
            continue
        fi
        if ! test -e "$f"
        then
            continue
        fi
        d="$BMC_PRESERVE_DIR/$f"
        while test "${d%/}" != "${d%/.}"
        do
            d="${d%/.}"
            d="${d%/}"
        done
        mkdir -p "${d%/*}"
        cp -rp "$f" "${d%/*}/"
    done < $whitelist
    
    if ! grep -q "^/etc/extlog" "$whitelist" 2>/dev/null; then
        rm -rf /etc/extlog/extended.log* > /dev/null 2>&1
    fi

    log "BMC Full Flash - Backup Configuration Done" 
}

restore_bmc_config() {
        log "BMC Full Flash - Start Restore Configuration"

        rm -rf $TMP_OVERLAY

        # clear SEL and ExtLog
	#	rm -rf /etc/extlog/phosphor-logging > /dev/null 2>&1

        # check and backup newly created and updated files to backup dir
        while read -r f
        do
            # Entries shall start with /, no trailing /.. or embedded /../
            if test "/${f#/}" != "$f" -o "${f%/..}" != "${f#*/../}"
            then
                echo 1>&2 "WARNING: Skipping bad whitelist entry $f."
                continue
            fi
            if ! test -e "$f"
            then
                continue
            fi
            d="$BMC_PRESERVE_DIR/$f"
            while test "${d%/}" != "${d%/.}"
            do
                d="${d%/.}"
                d="${d%/}"
            done
            mkdir -p "${d%/*}"
            cp -u -rp "$f" "${d%/*}/"
        done < $whitelist

        #mount rwfs partation to restore configs
        mount -t jffs2 -o rw mtd:rwfs $TMP_RWFS

        # copy required configs from backup dir to overlaydir
        cp -rp "$BMC_PRESERVE_DIR/." "$TMP_OVERLAY/"

        # unmount rwfs partation
        umount $TMP_RWFS

        log "BMC Full Flash - Restore Configuration Done"

        if [ "$is_Uboot_enabled" == true ]; then
            restore_uboot_env_data
        fi

        # Clear backup dir
        rm -rf $BMC_PRESERVE_DIR
}

check_preserve_bios_config() {
    value=$(busctl get-property xyz.openbmc_project.Software.BMC.Updater \
            /xyz/openbmc_project/software \
            xyz.openbmc_project.Software.ApplyOptions ClearConfig \
            | awk '{print $2}' )
    local mtdPart=$( cat /proc/mtd | awk '{print $1 $4}' | awk -F: '$2=="\"pnor\"" {print $1}')

    if [ ! -f $preserve_bios ]; then
        log "BIOS Full Flash - Preserve Configuration JSON not present"
        return
    fi

    if [ -n "$value" ]; then
        if [ "$value" = "true" ]; then
            log "BIOS Full Flash - Not Preserved the Config"
        else
            log "BIOS Full Flash - Start Preserve Config"

            json_data=$(cat $preserve_bios)

            config_keys=$(echo "$json_data" | grep -o '"[^"]*": {' | awk -F'"' '{print $2}')

            for key in $config_keys; do
                block=$(echo "$json_data" | awk -v RS="}" "/\"$key\"/ {print \$0 RS}")

                # Extract start, length value from the block
                start=$(echo "$block" | grep -o '"start": *"[^"]*"' | awk -F'"' '{print $4}')
                length=$(echo "$block" | grep -o '"length": *"[^"]*"' | awk -F'"' '{print $4}')

                nanddump -s $start -l $length /dev/$mtdPart > /tmp/preserve_bios_$key
                if [[ $? -eq 0 ]]; then
                    log "BIOS $key Configs Preserved successfully"
                else
                    log "BIOS $key Configs Preserved failed"
                fi

            done
        fi
    else
        log "ClearConfig is not available"
    fi
}

restore_bios_configs() {
    value=$(busctl get-property xyz.openbmc_project.Software.BMC.Updater \
            /xyz/openbmc_project/software \
            xyz.openbmc_project.Software.ApplyOptions ClearConfig \
            | awk '{print $2}' )

    if [ "$value" = "true" ]; then
        # set clear configs to false
        busctl set-property xyz.openbmc_project.Software.BMC.Updater \
            /xyz/openbmc_project/software \
            xyz.openbmc_project.Software.ApplyOptions ClearConfig \
            b false
        return
    fi

    if [ ! -f $preserve_bios ]; then
        log "BIOS Full Flash - Preserve Configuration JSON not present"
        return
    fi

    local mtdPart=$( cat /proc/mtd | awk '{print $1 $4}' | awk -F: '$2=="\"pnor\"" {print $1}')

    json_data=$(cat $preserve_bios)

    config_keys=$(echo "$json_data" | grep -o '"[^"]*": {' | awk -F'"' '{print $2}')

    for key in $config_keys; do
        block=$(echo "$json_data" | awk -v RS="}" "/\"$key\"/ {print \$0 RS}")

        # Extract start, length value from the block
        start=$(echo "$block" | grep -o '"start": *"[^"]*"' | awk -F'"' '{print $4}')

        nandwrite -s $start /dev/${mtdPart} /tmp/preserve_bios_$key
        if [[ $? -eq 0 ]]; then
            log "BIOS Full Flash - restore $key Configs Preserved successfully"
        else
            log "BIOS Full Flash - restore $key Configs Preserved failed"
        fi

    done

    for key in $config_keys; do
        rm -rf /tmp/preserve_bios_$key
    done

}

redfish_log_fw_evt() {
    evt=$1
    sev=""
    msg=""
    [ -z "$FWTYPE" ] && return
    [ -z "$FWVER" ] && return
    case "$evt" in
        start)
            update_percentage $UPDATE_PERCENT_PRESTAGE_VERIFY_COMPLETE
            evt=OpenBMC.0.4.0.FirmwareUpdateStarted
            msg="$FWTYPE firmware update to version $FWVER started."
            sev=Informational
            ;;
        success)
            update_percentage $UPDATE_PERCENT_SUCCESS
            evt=OpenBMC.0.4.0.FirmwareUpdateCompleted
            msg="$FWTYPE firmware update to version $FWVER completed successfully."
            sev=Informational
            ;;
        staged)
            update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_START
            evt=OpenBMC.0.4.0.FirmwareUpdateStaged
            msg="$FWTYPE firmware update to version $FWVER staged successfully."
            sev=Informational
            ;;
        *) return ;;
    esac
    create_Phosphor_log
    logger-systemd --journald <<-EOF
		MESSAGE=$msg
		PRIORITY=2
		SEVERITY=${sev}
		REDFISH_MESSAGE_ID=${evt}
		REDFISH_MESSAGE_ARGS=${FWTYPE},${FWVER}
		EOF
}

redfish_log_abort() {
    # local evt=""
    # local sev=""
    # local msg=""
    local reason=$1
    [ -z "$FWTYPE" ] && return
    [ -z "$FWVER" ] && return
    evt=OpenBMC.0.1.FirmwareUpdateFailed
    msg="$FWTYPE firmware update to version $FWVER failed: ${reason}."
    sev=Warning
    update_status $UPDATE_STATUS_EXCEPTION
    create_Phosphor_log
    logger-systemd --journald <<-EOF
		MESSAGE=$msg
		PRIORITY=2
		SEVERITY=${sev}
		REDFISH_MESSAGE_ID=${evt}
		REDFISH_MESSAGE_ARGS=${FWTYPE},${FWVER},${reason}
		EOF
}

wait_for_log_sync()
{
    sync
    sync /tmp/.rwfs/.overlay
    sleep 5
}


set_activation_status() {
    local status="$1"
    if [ $local_file -eq 0 ]; then
        busctl set-property xyz.openbmc_project.Software.BMC.Updater \
            /xyz/openbmc_project/software/$img_obj \
            xyz.openbmc_project.Software.Activation Activation \
            s "xyz.openbmc_project.Software.Activation.Activations.$status"
    fi
}


set_requestedactivation_status() {
    local status="$1"
    if [ $local_file -eq 0 ]; then
        busctl set-property xyz.openbmc_project.Software.BMC.Updater \
            /xyz/openbmc_project/software/$img_obj \
            xyz.openbmc_project.Software.Activation RequestedActivation \
            s "xyz.openbmc_project.Software.Activation.RequestedActivations.$status"
    fi
}

get_requestedactivation_status() {
    local image="$1"
    if [ $local_file -eq 0 ]; then
    busctl get-property xyz.openbmc_project.Software.BMC.Updater \
            /xyz/openbmc_project/software/$image \
            xyz.openbmc_project.Software.Activation RequestedActivation \
            | awk '/s / {print $2}' | sed 's/"//g'
    fi
}

get_pushuri_target() {
    busctl get-property xyz.openbmc_project.Software.BMC.Updater \
        /xyz/openbmc_project/software \
        xyz.openbmc_project.Software.FirmwareUpdateTarget HttpPushUriTargets \
        | awk -F'"' '{for(i=2;i<=NF;i+=2) print $i}'
}

Clear_pushuri_target_and_busy_status() {
    busctl set-property xyz.openbmc_project.Software.BMC.Updater \
        /xyz/openbmc_project/software \
        xyz.openbmc_project.Software.FirmwareUpdateTarget HttpPushUriTargets as 0

    busctl set-property xyz.openbmc_project.Software.BMC.Updater \
        /xyz/openbmc_project/software \
        xyz.openbmc_project.Software.FirmwareUpdateTarget HttpPushUriTargetsBusy b false
}

get_default_target() {
    local comp="$1"
    comp_array=()
    for obj in $(busctl --system call xyz.openbmc_project.ObjectMapper \
        /xyz/openbmc_project/object_mapper xyz.openbmc_project.ObjectMapper GetSubTreePaths \
        sias /xyz/openbmc_project/software 0 1 xyz.openbmc_project.Software.Version | tr -d '\"'); do
        if [[ "${obj,,}" == *"$comp"* ]]; then
            comp_array+=("${obj##*/}")
        fi
    done
    echo "${comp_array[@]}"
}

exit_fail() { 
    update_percentage $UPDATE_PERCENT_FAIL
    log "${FWTYPE}:${FWVER} - UPDATE_FAILED"
    DIR_PATH=$(dirname "$LOCAL_PATH")
    log "UPDATE_FAILED cleaning the $DIR_PATH path"
    rm -rf $DIR_PATH
    exit 1
}


ifwi_full_flash() {
    # Reading the version from IFWI image(64MB) is not possible.
    # So setting FWVER to "NA".
    # FWTYPE="BIOS"
    # FWVER="NA"
    redfish_log_fw_evt stage

    update_percentage $UPDATE_PERCENT_PRESTAGE_VERIFY_START


    # # Verify: do a quick sanity check on image size(64MB)
    # if [ $(stat -c "%s" "$LOCAL_PATH") -lt 67108864 ]; then
    #     log "IFWI Full Flash - Update file "$LOCAL_PATH" seems to be too small"
    #     redfish_log_abort "Update file too small"
    #     set_activation_status Failed
    #     update_percentage $UPDATE_PERCENT_FAIL
    #     return 1
    # fi

    update_percentage $UPDATE_PERCENT_PRESTAGE_VERIFY_COMPLETE
    update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_START
    mtdPart=$( cat /proc/mtd | awk '{print $1 $4}' | awk -F: '$2=="\"pnor\"" {print $1}')
    echo "mtdPart=$mtdPart"
    if [ -z "$mtdPart" ]; then
        log "IFWI Full Flash - host mtd patition not found"
        redfish_log_abort " IFWI Full Flash - Image update failed"      
        update_percentage $UPDATE_PERCENT_FAIL
        return 1
    fi

    # Flash: writing to BIOS SPI device
    check_preserve_bios_config
    log "IFWI Full Flash - Starting the SPI write. It will take ~5 minutes...."
    # local rc=$(mtd-util -d /dev/$mtdPart c $LOCAL_PATH 0)
    flashcp  $LOCAL_PATH /dev/$mtdPart
    if [[ $? -eq 0 ]]; then
        update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_COMPLETE
        log "IFWI Full Flash - Image update successful"
        restore_bios_configs
        redfish_log_fw_evt success
        update_percentage $UPDATE_PERCENT_SUCCESS         
        return 0
    else
        log "IFWI Full Flash - Image update failed"
        redfish_log_abort " IFWI Full Flash - Image update failed"        
        update_percentage $UPDATE_PERCENT_FAIL
	    return 1
    fi
}

backup_uboot_env_data() {
    local mtdPart=$( cat /proc/mtd | awk '{print $1 $4}' | awk -F: '$2=="\"u-boot-env\"" {print $1}')
    local mtd_size=$(printf "%x\n" $(cat /sys/class/mtd/${mtdPart}/size))
    if [ "$is_intel_platform" != true ]; then
        local rc=$(mtd_debug read /dev/${mtdPart} 0 0x${mtd_size} /run/initramfs/${uboot_env_bin_file})
    else
        local rc=$(mtd_debug read /dev/${mtdPart} 0 0x${mtd_size} /tmp/${uboot_env_bin_file})
    fi
    if test "$rc" == ""; then
        log "BMC Full Flash - backup u-boot-env parition failed"
        redfish_log_abort " BMC Full Flash - backup u-boot-env parition failed"
    fi
}

restore_uboot_env_data() {
    local mtdPart=$( cat /proc/mtd | awk '{print $1 $4}' | awk -F: '$2=="\"u-boot-env\"" {print $1}')
    local rc=$(mtd-util -d /dev/${mtdPart} c /tmp/${uboot_env_bin_file} 0)
    if [[ "$rc" -ne 0 ]]; then
        log "BMC Full Flash - restore u-boot-env parition failed"
        redfish_log_abort " BMC Full Flash - restore u-boot-env parition failed"
    fi
}

bmc_full_flash() {
    # Reading the version from 128MB binary is not possible.
    # So setting FWVER to "NA".
    # FWTYPE="BMC"
    # FWVER="NA"
    redfish_log_fw_evt staged

    update_percentage $UPDATE_PERCENT_PRESTAGE_VERIFY_START
    Check_and_update_whitelist
    # Use update script to update Firmware for non-intel platforms
    if test -x $update; then
        if [ -f $SLOT_FILE ]; then
            SLOT_FILE="/run/media/slot"
            BOOT_SOURCE=$(cat "$SLOT_FILE")
            ABR_BOOT_MODE="/sys/class/spi_master/spi0/device/abr_bootmode"
            bootmode=$(cat "$ABR_BOOT_MODE")
            # check_preserv_config $NON_INTEL_PLATFORMS_MODE
            local requestedactivationstate=$(get_requestedactivation_status bmc_bkup)
            local bmc_active_requestedactivationstate=$(get_requestedactivation_status bmc_active)
            if [[ "$bmc_active_requestedactivationstate" == "xyz.openbmc_project.Software.Activation.RequestedActivations.Active" && "$requestedactivationstate" == "xyz.openbmc_project.Software.Activation.RequestedActivations.Active" ]]; then
                log "Start Update Both BMC Active and Backup  images. It will take ~20 minutes...."
                log "BMC Full Flash - Starting the SPI write on active CS0 spi...."
                cp $LOCAL_PATH /run/initramfs/
                log "BMC Full Flash - Starting the SPI write on bkup CS1 spi...."
                if [ "$bootmode" -eq 1 ]; then
                    cp $LOCAL_PATH /run/initramfs/image-alt-singleabr
                else
                    cp $LOCAL_PATH /run/initramfs/image-alt-bmc
                    /usr/bin/reset-cs0-aspeed
                fi
            elif [[ "$requestedactivationstate" == "xyz.openbmc_project.Software.Activation.RequestedActivations.Active" ]]; then
                if [ "$BOOT_SOURCE" -eq 0 ]; then
                    log "BMC Full Flash - Starting the SPI write on bkup CS1 spi...."
                    if [ "$bootmode" -eq 1 ]; then
                        cp $LOCAL_PATH /run/initramfs/image-alt-singleabr
                    else
                        cp $LOCAL_PATH /run/initramfs/image-alt-bmc
                    fi
                else
                    log "BMC Full Flash - BMC booted from Backup SPI starting the SPI write on bkup CS1 spi...."
                    if [ "$bootmode" -eq 1 ]; then
                        cp $LOCAL_PATH /run/initramfs/image-alt-singleabr
                    else
                        cp $LOCAL_PATH /run/initramfs/
                    fi
                fi
            else
                if [ "$BOOT_SOURCE" -eq 0 ]; then
                    log "BMC Full Flash - Starting the SPI write on active CS0 spi...."
                    cp $LOCAL_PATH /run/initramfs/
                else
                    log "BMC Full Flash - BMC booted from Backup SPI starting the SPI write on active CS0 spi...."
                    if [ "$bootmode" -eq 1 ]; then
                        cp $LOCAL_PATH /run/initramfs/
                    else
                        cp $LOCAL_PATH /run/initramfs/image-alt-bmc
                    fi
                    /usr/bin/reset-cs0-aspeed
                fi
            fi

            # Stop nv sync
            systemctl stop nv-sync.service
            systemctl stop xyz.openbmc_project.Software.Sync.service
            for mtd in /dev/mtdblock*; do
                mountpoint=$(mount | grep "$mtd" | awk '{print $3}')
                if [ -n "$mountpoint" ]; then
                    echo "Unmounting $mtd from $mountpoint"
                    umount "$mountpoint"
                fi
            done
            /run/initramfs/update
            result=$?
            if [[ "$result" -ne 0 ]]; then
                log "BMC Full Flash - Image update failed"
                redfish_log_abort "BMC Full Flash - Image update failed"
                update_percentage $UPDATE_PERCENT_FAIL
                log "Cleaning up image files from /run/initramfs"
                rm -f /run/initramfs/image*
                return 1
            fi
            redfish_log_fw_evt success
            update_percentage $UPDATE_PERCENT_SUCCESS
            log "Cleaning up image files from /run/initramfs"
            rm -f /run/initramfs/image*
            return 0
        else
            log "BMC Full Flash - Starting the SPI write. It will take ~8 minutes...."
            # check_preserv_config $NON_INTEL_PLATFORMS_MODE
            cp $LOCAL_PATH /run/initramfs/
            # Stop nv sync
            systemctl stop nv-sync.service
            # Unmount rwfs
            umount $TMP_RWFS
            /run/initramfs/update
            result=$?
            if [[ "$result" -ne 0 ]]; then
                log "BMC Full Flash - Image update failed"
                redfish_log_abort "BMC Full Flash - Image update failed"
                update_percentage $UPDATE_PERCENT_FAIL
                log "Cleaning up image files from /run/initramfs"
                rm -f /run/initramfs/image*
                return 1
            fi
            redfish_log_fw_evt success
            update_percentage $UPDATE_PERCENT_SUCCESS
            log "Cleaning up image files from /run/initramfs"
            rm -f /run/initramfs/image*
            return 0
        fi  # This was missing
    else
        if [ -f $SLOT_FILE ]; then
            SLOT_FILE="/run/media/slot"
            BOOT_SOURCE=$(cat "$SLOT_FILE")
            log "BMC Full Flash - Booted from CS$BOOT_SOURCE"
            update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_START
            local requestedactivationstate=$(get_requestedactivation_status bmc_bkup)
            local bmc_active_requestedactivationstate=$(get_requestedactivation_status bmc_active)
            if [[ "$bmc_active_requestedactivationstate" == "xyz.openbmc_project.Software.Activation.RequestedActivations.Active" && "$requestedactivationstate" == "xyz.openbmc_project.Software.Activation.RequestedActivations.Active" ]]; then
                # First Update Image on CS0 SPI (BMC Active image)
                log "Start Update Both BMC Active and Backup  images. It will take ~20 minutes...."
                log "BMC Full Flash - Starting the SPI write on active CS0 spi. It will take ~8 minutes...."
                local mtdPart=$(cat /proc/mtd | awk '{print $1 $4}' | awk -F: '$2=="\"bmc\"" {print $1}')
                # if [[ "$applytime" == "$immediate" || "$applytime" == "$atMaintenanceWindowStart"  ]];then
                #     # stop nv sync
                #     systemctl stop nv-sync.service
                #     # unmount rwfs
                #     umount /tmp/.rwfs
                # fi 
                systemctl stop xyz.openbmc_project.Software.Sync.service
                Backup_bmc_config

                local rc=$(mtd-util -d /dev/$mtdPart c $LOCAL_PATH 0)

                # Log Event: Update percentage and log event
                update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_COMPLETE
                if [[ "$rc" -ne 0 ]]; then
                    log "BMC Full Flash - Image update failed"
                    redfish_log_abort " BMC Full Flash - Image update failed"
                    update_percentage $UPDATE_PERCENT_FAIL
                    return 1
                fi
                log "BMC Full Flash - Image update successful on active CS0 spi"
                sleep 5
                # After First Update Image update successfully update Backup image
                log "BMC Full Flash - Starting the SPI write on bkup CS1 spi. It will take ~8 minutes...."
                ABR_BOOT_MODE="/sys/class/spi_master/spi0/device/abr_bootmode"
                bootmode=$(cat "$ABR_BOOT_MODE")

                if [ "$bootmode" -eq 1 ]; then
                    local mtdPart=$( cat /proc/mtd | awk '{print $1 $4}' | awk -F: '$2=="\"bmc\"" {print $1}')
                    flashoffset=$(stat -c "%s" $LOCAL_PATH)
                    flashoffset=$(printf "%x\n" $flashoffset)
                else
                    local mtdPart=$(cat /proc/mtd | awk '{print $1 $4}' | awk -F: '$2=="\"alt-bmc\"" {print $1}')
                    flashoffset=0
                fi

                echo "mtdPart=$mtdPart"
                if [ -z "$mtdPart" ]; then
                    log "BMC Full Flash - mtd $mtdPart partition not found"
                    redfish_log_abort " BMC Full Flash - Image update failed"
                    set_requestedactivation_status None
                    update_percentage $UPDATE_PERCENT_FAIL
                    return 1
                fi
                local rc=$(mtd-util -d /dev/$mtdPart c $LOCAL_PATH 0x$flashoffset)
                # Log Event: Update percentage and log event
                if [[ "$rc" -ne 0 ]]; then
                    log "BMC Full Flash - Image update failed on backup spi"
                    redfish_log_abort " BMC Full Flash - Image update failed spi"
                    set_requestedactivation_status None
                    update_percentage $UPDATE_PERCENT_FAIL
                    return 1
                fi
                update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_COMPLETE
                # check_preserv_config
                redfish_log_fw_evt success
                restore_bmc_config
                log "BMC Full Flash - Image updated successful on bkup spi"
                update_percentage $UPDATE_PERCENT_SUCCESS
                sleep 5
                return 0
            elif [[ "$requestedactivationstate" == "xyz.openbmc_project.Software.Activation.RequestedActivations.Active" ]]; then
                ABR_BOOT_MODE="/sys/class/spi_master/spi0/device/abr_bootmode"
                bootmode=$(cat "$ABR_BOOT_MODE")
                if [ "$BOOT_SOURCE" -eq 0 ]; then
                    log "BMC Full Flash - Starting the SPI write on bkup CS1 spi. It will take ~8 minutes...."
		    if [ "$bootmode" -eq 1 ]; then
                        local mtdPart=$( cat /proc/mtd | awk '{print $1 $4}' | awk -F: '$2=="\"bmc\"" {print $1}')
                        flashoffset=$(stat -c "%s" $LOCAL_PATH)
                        flashoffset=$(printf "%x\n" $flashoffset)
                    else
                        local mtdPart=$(cat /proc/mtd | awk '{print $1 $4}' | awk -F: '$2=="\"alt-bmc\"" {print $1}')
                        flashoffset=0
                    fi
                else
                    log "BMC Full Flash - Starting the SPI write on bkup CS1 spi. It will take ~8 minutes...."
                    local mtdPart=$(cat /proc/mtd | awk '{print $1 $4}' | awk -F: '$2=="\"bmc\"" {print $1}')
                    flashoffset=0
                    # if [[ "$applytime" == "$immediate" || "$applytime" == "$atMaintenanceWindowStart"  ]];then
                    #     # stop nv sync
                    #     systemctl stop nv-sync.service
                    #     # unmount rwfs
                    #     umount /tmp/.rwfs
                    # fi    
                    Backup_bmc_config

                fi
                echo "mtdPart=$mtdPart"
                if [ -z "$mtdPart" ]; then
                    log "BMC Full Flash - mtd $mtdPart partition not found"
                    redfish_log_abort " BMC Full Flash - Image update failed"
                    set_requestedactivation_status None
                    update_percentage $UPDATE_PERCENT_FAIL
                    return 1
                fi
                local rc=$(mtd-util -d /dev/$mtdPart c $LOCAL_PATH 0x$flashoffset)
                # Log Event: Update percentage and log event
                if [[ "$rc" -ne 0 ]]; then
                    log "BMC Full Flash - Image update failed"
                    redfish_log_abort " BMC Full Flash - Image update failed"
                    set_requestedactivation_status None
                    update_percentage $UPDATE_PERCENT_FAIL
                    return 1
                fi
                update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_COMPLETE
                redfish_log_fw_evt success
                if [ "$BOOT_SOURCE" -eq 1 ]; then
                    # check_preserv_config
                    restore_bmc_config
                fi
                log "BMC Full Flash - Image update successful on bkup spi"
                update_percentage $UPDATE_PERCENT_SUCCESS
                sleep 5
                return 0
            else
                if [ "$BOOT_SOURCE" -eq 0 ]; then
                    log "BMC Full Flash - Starting the SPI write on active CS0 spi. It will take ~8 minutes...."
                    local mtdPart=$(cat /proc/mtd | awk '{print $1 $4}' | awk -F: '$2=="\"bmc\"" {print $1}')
                    # if [[ "$applytime" == "$immediate" || "$applytime" == "$atMaintenanceWindowStart"  ]];then
                    #     # stop nv sync
                    #     systemctl stop nv-sync.service
                    #     # unmount rwfs
                    #     umount /tmp/.rwfs
                    # fi
                    Backup_bmc_config
                else
                    log "BMC Full Flash - Starting the SPI write on active CS0 spi. It will take ~8 minutes...."
                    local mtdPart=$(cat /proc/mtd | awk '{print $1 $4}' | awk -F: '$2=="\"alt-bmc\"" {print $1}')
                fi

                local rc=$(mtd-util -d /dev/$mtdPart c $LOCAL_PATH 0)

                # Log Event: Update percentage and log event
                update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_COMPLETE
                if [[ "$rc" -ne 0 ]]; then
                    log "BMC Full Flash - Image update failed"
                    redfish_log_abort " BMC Full Flash - Image update failed"
                    update_percentage $UPDATE_PERCENT_FAIL
                    return 1
                fi
                log "BMC Full Flash - Image update successful"
                redfish_log_fw_evt success
                if [ "$BOOT_SOURCE" -eq 0 ]; then
                    # check_preserv_config
                    restore_bmc_config
                else
                    ACCESS_CS0="/sys/class/spi_master/spi0/device/access_primary"
                    if [ -f "${ACCESS_CS0}" ]; then
                        echo "Reset aspeed chip select"
                        echo 1 > "${ACCESS_CS0}"
                    fi
                fi
                update_percentage $UPDATE_PERCENT_SUCCESS
                sleep 5
                return 0
            fi
        fi
        # if [[ "$applytime" == "$immediate" || "$applytime" == "$atMaintenanceWindowStart"  ]];then
        #     #stop nv sync
        #     systemctl stop nv-sync.service
        #     #unmount rwfs  
        #     umount /tmp/.rwfs
        # fi
        Backup_bmc_config
        # Flash: writing to BMC SPI device
        log "BMC Full Flash - Starting the SPI write. It will take ~8 minutes...."
        local rc=$(mtd-util -d /dev/mtd0 c $LOCAL_PATH 0)

        # Log Event: Update percentage and log event
        update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_COMPLETE
        if [[ "$rc" -ne 0 ]]; then
            log "BMC Full Flash - Image update failed"
            redfish_log_abort " BMC Full Flash - Image update failed"
            update_percentage $UPDATE_PERCENT_FAIL
            return 1
        fi
        log "BMC Full Flash - Image update successful"
        # check_preserv_config
        redfish_log_fw_evt success
        restore_bmc_config
        update_percentage $UPDATE_PERCENT_SUCCESS
        sleep 5
        return 0
    fi
}


host_powered_off() {
    local host_state=$(busctl get-property \
    xyz.openbmc_project.State.Host /xyz/openbmc_project/state/host0 \
    xyz.openbmc_project.State.Host CurrentHostState)

    if [[ "$host_state" == *HostState.Off* ]]; then
        return 0
    fi

    return 1
}

ping_pong_update() {
    # if some one tries to update with non-PFR on PFR image
    # just exit
    if [ -e /usr/share/pfr ]; then
        log "Update exited as non-PFR image is tried onto PFR image"
        redfish_log_abort "non-PFR image is tried onto PFR image"
        return 1
    fi

    redfish_log_fw_evt staged
    update_percentage $UPDATE_PERCENT_PRESTAGE_VERIFY_START
    if test -x $update
	then
        update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_START
        if [[ "$bmc_active_requestedactivationstate" == "xyz.openbmc_project.Software.Activation.RequestedActivations.Active" && "$requestedactivationstate" == "xyz.openbmc_project.Software.Activation.RequestedActivations.Active" ]]; then
            log "Start Update Both BMC Active and Backup  images. It will take ~20 minutes...."
            find $(dirname "$METAFILE_PATH") -type f -name "image-*" ! -name "*.sig" -exec cp {} /run/initramfs/ \;
            find $(dirname "$METAFILE_PATH") -type f -name "image-*" ! -name "*.sig" -exec bash -c 'cp "$1" /run/initramfs/$(basename "$1" | sed "s/^image-/image-alt-/")' _ {} \;
        elif [[ "$requestedactivationstate" == "xyz.openbmc_project.Software.Activation.RequestedActivations.Active" ]]; then
            log "Start Update Both BMC Backup image. It will take ~8 minutes...."
            find $(dirname "$METAFILE_PATH") -type f -name "image-*" ! -name "*.sig" -exec bash -c 'cp "$1" /run/initramfs/$(basename "$1" | sed "s/^image-/image-alt-/")' _ {} \;
        else
            log "Start Update Both BMC Active image. It will take ~8 minutes...."
            find $(dirname "$METAFILE_PATH") -type f -name "image-*" ! -name "*.sig" -exec cp {} /run/initramfs/ \;
        fi
        # Stop nv sync
        systemctl stop nv-sync.service
        systemctl stop xyz.openbmc_project.Software.Sync.service
        for mtd in /dev/mtdblock*; do
            mountpoint=$(mount | grep "$mtd" | awk '{print $3}')
            if [ -n "$mountpoint" ]; then
                echo "Unmounting $mtd from $mountpoint"
                umount "$mountpoint"
            fi
        done
        /run/initramfs/update
        result=$?
        if [[ "$result" -ne 0 ]]; then
            log "BMC Full Flash - Image update failed"
            redfish_log_abort "BMC Full Flash - Image update failed"
            update_percentage $UPDATE_PERCENT_FAIL
            log "Cleaning up image files from /run/initramfs"
            rm -f /run/initramfs/image*
            return 1
        fi
        redfish_log_fw_evt success
        update_percentage $UPDATE_PERCENT_SUCCESS
        log "Cleaning up image files from /run/initramfs"
        rm -f /run/initramfs/image*
        return 0
    fi
    # do a quick sanity check on the image
    if [ $(stat -c "%s" "$LOCAL_PATH") -lt 10000000 ]; then
        log "Update file "$LOCAL_PATH" seems to be too small"
        redfish_log_abort "Update file too small"
        return 1
    fi
    update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_START
    # dtc -I dtb -O dtb "$LOCAL_PATH" > /dev/null 2>&1
    # if [ $? -ne 0 ]; then
    #     log "Update file $LOCAL_PATH doesn't seem to be in the proper format"
    #     redfish_log_abort "Invalid file format"
    #     return 1
    # fi

    # guess based on fw_env which partition we booted from
    # local BOOTADDR=$(fw_printenv bootcmd | awk '{print $2}')
    local TGT="/dev/mtd/image-a"
    # case "$BOOTADDR" in
    #     20080000) TGT="/dev/mtd/image-b"; BOOTADDR="22480000" ;;
    #     22480000) TGT="/dev/mtd/image-a"; BOOTADDR="20080000" ;;
    #     *)        TGT="/dev/mtd/image-a"; BOOTADDR="20080000" ;;
    # esac
    systemctl stop nv-sync.service
    local requestedactivationstate=$(get_requestedactivation_status bmc_bkup)
    local bmc_active_requestedactivationstate=$(get_requestedactivation_status bmc_active)
    if [[ "$bmc_active_requestedactivationstate" == "xyz.openbmc_project.Software.Activation.RequestedActivations.Active" && "$requestedactivationstate" == "xyz.openbmc_project.Software.Activation.RequestedActivations.Active" ]]; then
        log "Start Update Both BMC Active and Backup  images. It will take ~20 minutes...."
        TGT="/dev/mtd/image-a"
        log "Updating $(basename $TGT), It will take ~8 minutes...."
        flash_erase $TGT 0 0
        log "Writing $(stat -c "%s" "$LOCAL_PATH") bytes"
        cat "$LOCAL_PATH" > "$TGT"
        if [ $? -eq 0 ]; then
            log "$(basename $TGT) updated successfully"
        else
            log "$(basename $TGT) updated failed"
            redfish_log_abort " $(basename $TGT) - Image update failed"        
            update_percentage $UPDATE_PERCENT_FAIL
	        return 1
        fi
        TGT="/dev/mtd/alt-image-a"
        log "Updating $(basename $TGT), It will take ~8 minutes...."
        flash_erase $TGT 0 0
        log "Writing $(stat -c "%s" "$LOCAL_PATH") bytes"
        cat "$LOCAL_PATH" > "$TGT"
        if [ $? -eq 0 ]; then
            log "$(basename $TGT) updated successfully"
        else
            log "$(basename $TGT) updated failed"
            redfish_log_abort " $(basename $TGT) - Image update failed"        
            update_percentage $UPDATE_PERCENT_FAIL
	        return 1
        fi
    elif [[ "$requestedactivationstate" == "xyz.openbmc_project.Software.Activation.RequestedActivations.Active" ]]; then
        TGT="/dev/mtd/alt-image-a"
        log "Updating $(basename $TGT), It will take ~8 minutes...."
        flash_erase $TGT 0 0
        log "Writing $(stat -c "%s" "$LOCAL_PATH") bytes"
        cat "$LOCAL_PATH" > "$TGT"
        if [ $? -eq 0 ]; then
            log "$(basename $TGT) updated successfully"
        else
            log "$(basename $TGT) updated failed"
            redfish_log_abort " $(basename $TGT) - Image update failed"        
            update_percentage $UPDATE_PERCENT_FAIL
	        return 1
        fi
    else
        log "Updating $(basename $TGT), It will take ~8 minutes...."
        flash_erase $TGT 0 0
        log "Writing $(stat -c "%s" "$LOCAL_PATH") bytes"
        cat "$LOCAL_PATH" > "$TGT"
        if [ $? -eq 0 ]; then
            log "$(basename $TGT) updated successfully"
        else
            log "$(basename $TGT) updated failed"
            redfish_log_abort " $(basename $TGT) - Image update failed"        
            update_percentage $UPDATE_PERCENT_FAIL
	        return 1
        fi
    fi
    systemctl start nv-sync.service
    # fw_setenv "bootcmd" "bootm ${BOOTADDR}"
    redfish_log_fw_evt success
    wait_for_log_sync
    if [[ "$applytime" == "$immediate" || "$applytime" == "$atMaintenanceWindowStart"  ]];then
        # stop the nv-sync.service to trigger the overlay sync and unmount before 'reboot -f'
        systemctl stop nv-sync.service
    fi    
    update_percentage $UPDATE_PERCENT_SUCCESS
    return 0
}

cpld_full_flash()
{
    redfish_log_fw_evt staged
    echo "cpld full falsh called"
    update_percentage $UPDATE_PERCENT_PRESTAGE_VERIFY_START
    update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_START
    # Flash: writing to cpld device
    service="xyz.openbmc_project.EntityManager"
    interface="xyz.openbmc_project.Configuration.CPLD"
    cpldpath=$(busctl --system call xyz.openbmc_project.ObjectMapper /xyz/openbmc_project/object_mapper \
         xyz.openbmc_project.ObjectMapper GetSubTreePaths sias "/" 0 1 "xyz.openbmc_project.Inventory.Item.Cpld" | awk '/s/ {print $3}' | tr -d '"')
    extractedCpldName=$(basename "$cpldpath")
    objpath="/xyz/openbmc_project/inventory/system/board/Cpld/$extractedCpldName"
    InputParameters=$(busctl get-property $service $objpath $interface InputParameters | cut -d' ' -f2- | tr -d '"')
    log "CPLD Flash - Starting the cpld write....."
    # Log Event: Update percentage and log event
    update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_COMPLETE
    cmd="cpld-tool $InputParameters -p $LOCAL_PATH"
    log "issuing... $cmd" 
    cpld_output=$($cmd)
    if echo "$cpld_output" | grep -q "failed"; then
        log "CPLD Flash - Image update failed"
        log "$cpld_output"
        redfish_log_abort " CPLD Flash - Image update failed"
        update_percentage $UPDATE_PERCENT_FAIL
        return 1
    fi
        log "CPLD Flash - Image update successful"
        update_percentage $UPDATE_PERCENT_SUCCESS
        cmd="cpld-tool $InputParameters -u"
        echo $cmd >&2
        cpld_output=$( $cmd )
        # Check the exit status of the cpld-tool command
        if [ $? -eq 0 ]; then
            # Extract the usercode from the output
            if echo "$cpld_output" | grep -q "Lattice USERCODE="; then
            usercode=$(echo "$cpld_output" | grep "Lattice USERCODE" |  cut -d= -f2 )
            else
            usercode="NA"
            fi
        fi
        log "CPLD Flash - USERCODE = $usercode"
        servicename=$(mapper get-service $cpldpath)
	    busctl set-property $servicename \
            $cpldpath \
            xyz.openbmc_project.Software.Version Version \
            s $usercode
        redfish_log_fw_evt success
        return 0
}

pldm_update() {
    redfish_log_fw_evt staged
    local buffer=""
    local found=0
    local obj_path=""
    local image_copied=0

    while read -r line; do
        # Ensure copy starts only once and after monitor begins
        if [ "$image_copied" -eq 0 ]; then
            echo "Copying image to ot-pldm directory..."
            rand=$(printf "%06d" $((RANDOM % 1000000)))
            cp "$LOCAL_PATH" "/tmp/images/ot-pldm/image$rand"
            image_copied=1
        fi

        # Clean line formatting
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Look for object path line (dbus-monitor format)
        if echo "$line" | grep -q '^object path'; then
            obj_path=$(echo "$line" | awk -F'"' '{print $2}')
            buffer=""
            continue
        fi

        # Accumulate lines for parsing full block
        buffer="${buffer}
${line}"

        # Check if Activation interface appeared
        if echo "$buffer" | grep -q "xyz.openbmc_project.Software.Activation" && [ -n "$obj_path" ]; then
            echo "Found object with Activation interface: $obj_path"
            found=1
            break
        fi
    done < <(timeout 40s dbus-monitor --system \
        "type='signal',interface='org.freedesktop.DBus.ObjectManager',member='InterfacesAdded',path='/xyz/openbmc_project/software'") || {
        log "Timeout expired while waiting for InterfacesAdded signal with xyz.openbmc_project.Software.Activation."
        redfish_log_abort "PLDM Update - Activation interface not found"
        update_percentage $UPDATE_PERCENT_FAIL
        return 1
    }

    local image_activated=0
    local found_progress=0
    local found_activation=0
    local found_activation_property=0

    while read -r line; do
        if [ "$image_activated" -eq 0 ]; then
            if [ -n "$obj_path" ]; then
                busctl set-property \
                    xyz.openbmc_project.PLDM \
                    "$obj_path" \
                    xyz.openbmc_project.Software.Activation \
                    RequestedActivation \
                    s \
                    xyz.openbmc_project.Software.Activation.RequestedActivations.Active || {
                        log "Error: Failed to set RequestedActivation to 'Active'."
                        return 1
                    }
            else
                log "Error: obj_path is empty or invalid. Cannot set RequestedActivation."
                redfish_log_abort "PLDM Update - RequestedActivation failed"
                update_percentage $UPDATE_PERCENT_FAIL
                return 1
            fi
            image_activated=1
        fi

        if echo "$line" | grep -q "xyz.openbmc_project.Software.ActivationProgress"; then
            found_progress=1
        elif [ "$found_progress" = "1" ] && echo "$line" | grep -q 'variant'; then
            progress=$(echo "$line" | awk '/variant/ {print $NF}')
            echo "Progress: $progress%"
            found_progress=0
        fi

        if echo "$line" | grep -q 'string "xyz.openbmc_project.Software.Activation"'; then
            found_activation=1
            found_activation_property=0
        fi

        if [ "$found_activation" = "1" ] && echo "$line" | grep -q 'string "Activation"'; then
            found_activation_property=1
        fi

        if [ "$found_activation" = "1" ] && [ "$found_activation_property" = "1" ] && echo "$line" | grep -q 'variant'; then
            if echo "$line" | grep -q "xyz.openbmc_project.Software.Activation.Activations.Failed"; then
                log "Activation failed."
                redfish_log_abort "PLDM Update - Activation failed"
                update_percentage "$UPDATE_PERCENT_FAIL"
                return 1
            elif echo "$line" | grep -q "xyz.openbmc_project.Software.Activation.Activations.Invalid"; then
                log "Activation invalid."
                redfish_log_abort "PLDM Update - Activation invalid"
                update_percentage "$UPDATE_PERCENT_FAIL"
                return 1
            elif echo "$line" | grep -q "xyz.openbmc_project.Software.Activation.Activations.NotReady"; then
                log "Activation not ready."
                redfish_log_abort "PLDM Update - Activation NotReady"
                update_percentage "$UPDATE_PERCENT_FAIL"
                return 1
            elif echo "$line" | grep -q "xyz.openbmc_project.Software.Activation.Activations.Active"; then
                echo "Activation succeeded."
                log "Activation completed successfully."
                redfish_log_fw_evt success
                return 0
            fi

            found_activation=0
            found_activation_property=0
        fi
    done < <(timeout 1600s dbus-monitor --system \
        "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='$obj_path'") || {
        log "Error: Failed to monitor D-Bus properties for activation progress due to timeout."
        redfish_log_abort "PLDM Update - Activation progress monitoring failed"
        update_percentage $UPDATE_PERCENT_FAIL
        return 1
    }

    kill -9 $(pgrep -f "dbus-monitor --system type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='$obj_path'") 2>/dev/null
    return 0
}

raid_update() {
    read -ra updaterList <<< "$(get_pushuri_target)"
    if [[ ${#updaterList[@]} -eq 0 ]]; then
        read -ra default_comp <<< "$(get_default_target raid)"
        read -ra default_comp_hba <<< "$(get_default_target hba)"
        read -ra default_mscc_raid <<< "$(get_default_target ctrl)"
        default_comp+=("${default_mscc_raid[@]}")
        default_comp+=("${default_comp_hba[@]}")
        if [[ ${#default_comp[@]} -gt 1 ]]; then
            log "Kindly update one RAID component in target to update Firmware"
            log "RAID: ${default_comp[@]}"
            exit_fail
        else
            updaterList=("${default_comp[@]}")
        fi
    fi
    outputfile=/tmp/signal_output.txt
    SIGNAL_RECEIVED=0
    update_percentage $UPDATE_PERCENT_PRESTAGE_VERIFY_START
    update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_START
    for targetPath in $updaterList; do
        targetRaidId="${targetPath##*_}"
        targetRAIDType="${targetPath%%_*}"
        targetRAIDSubType=$(echo "${targetPath#*_}" | cut -d'_' -f1)
        TIMEOUT=600  # Set a timeout in seconds (10 min)
        SECONDS=0

        log "Start $targetPath RAID Firmware update"

        if [ "$targetRAIDType" == "Broadcom" ]; then
            if [ "$targetRAIDSubType" == "CTRL" ]; then
                busctl monitor --match "type='signal',sender='com.ami.storage',member='MethodCompletedSignal'" > $outputfile &
                buscall_id=$!

                busctl call com.ami.storage /com/ami/storage/brcm8/ctrl/$targetRaidId com.ami.storage.brcm8.ctrl.Configuration \
                FlashFirmware s "$LOCAL_PATH"
            else
                raidSubType=$( [ "$targetRAIDSubType" == "HBA" ] && echo 'HBA' || echo 'Raid' )
                raidSubTypeInterface=$( [ "$targetRAIDSubType" == "HBA" ] && echo 'hba' || echo 'raid' )

                busctl monitor --match "type='signal',sender='xyz.openbmc_project.$raidSubTypeInterface.manager',member='MethodCompletedSignal'" > $outputfile &
                buscall_id=$!
                RaidId=$(busctl get-property xyz.openbmc_project.$raidSubTypeInterface.manager \
                        /xyz/openbmc_project/$raidSubType/$targetRaidId \
                        xyz.openbmc_project.$raidSubTypeInterface.Controller Id \
                        | awk '{print $2}')

                busctl call xyz.openbmc_project.$raidSubTypeInterface.manager /xyz/openbmc_project/$raidSubType \
                        xyz.openbmc_project.$raidSubTypeInterface.Base FlashControllerFirmware us "$RaidId" "$LOCAL_PATH"
            fi
        elif [ "$targetRAIDType" == "Microchip" ]; then

            busctl monitor --match "type='signal',sender='com.ami.storage',member='MethodCompletedSignal'" > $outputfile &
            buscall_id=$!
            busctl call com.ami.storage /com/ami/storage/mscc/ctrl/$targetRaidId com.ami.storage.mscc.ctrl.Configuration \
                FlashControllerFirmware s "$LOCAL_PATH"
        fi

        while [ $SECONDS -lt $TIMEOUT ]; do
            if grep -q "MethodCompletedSignal" $outputfile; then
                if [ "$targetRAIDType" == "Microchip" ]; then
                    getStatus=$(grep 'STRING "com.ami.storage' $outputfile | tail -n 1 | cut -d '"' -f 2 | awk -F'.' '{print $NF}')
                    if [[ "$getStatus" != "Progress" ]]; then
                        SIGNAL_RECEIVED=1
                        break
                    fi
                else
                    SIGNAL_RECEIVED=1
                    break
                fi
            fi
            sleep 1
            SECONDS+=1
        done

        kill $buscall_id

        update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_COMPLETE

        if [ $SIGNAL_RECEIVED -eq 1 ]; then
            ERROR_CODE=$(grep 'STRING' $outputfile | head -n 1 | cut -d '"' -f 2)
            STATUS_MESSAGE=$(grep 'STRING' $outputfile | tail -n 1 | cut -d '"' -f 2)

            if [ "$STATUS_MESSAGE" == "Success" ]; then
                log "$targetPath RAID updated successfully"
            else
                log "Failed to update RAID $targetPath"
                update_percentage $UPDATE_PERCENT_FAIL
                # exit_fail
                Clear_pushuri_target_and_busy_status
                return 1
            fi

            SIGNAL_RECEIVED=0
        else
            log "Failed to receive signal."
            # exit_fail
            Clear_pushuri_target_and_busy_status
            return 1
        fi
    done
    update_percentage $UPDATE_PERCENT_SUCCESS
    Clear_pushuri_target_and_busy_status
    return 0
}


fetch_fw() {
    update_percentage $UPDATE_PERCENT_FETCH_START
    PROTO=$(echo "$URI" | sed 's,\([a-z]*\)://.*$,\1,')
    REMOTE=$(echo "$URI" | sed 's,.*://\(.*\)$,\1,')
    REMOTE_HOST=$(echo "$REMOTE" | sed 's,\([^/]*\)/.*$,\1,')
    if [ "$PROTO" = 'scp' ]; then
        REMOTE_PATH=$(echo "$REMOTE" | cut -d':' -f2)
    else
        REMOTE_PATH=$(echo "$REMOTE" | sed 's,[^/]*/\(.*\)$,\1,')
    fi
    LOCAL_PATH="/tmp/$(basename $REMOTE_PATH)"
    log "PROTO=$PROTO"
    log "REMOTE=$REMOTE"
    log "REMOTE_HOST=$REMOTE_HOST"
    log "REMOTE_PATH=$REMOTE_PATH"
    if [ ! -e $LOCAL_PATH ] || [ $(stat -c %s $LOCAL_PATH) -eq 0 ]; then
        log "Download '$REMOTE_PATH' from $PROTO $REMOTE_HOST $REMOTE_PATH"
        case "$PROTO" in
            scp)
                mkdir -p $HOME/.ssh
                if [ -e "$SSH_ID" ]; then
                    ARG_ID="-i $SSH_ID"
                fi
                scp $ARG_ID $REMOTE_HOST$REMOTE_PATH $LOCAL_PATH
                if [ $? -ne 0 ]; then
                    log "scp $REMOTE $LOCAL_PATH failed!"
                    return 1
                fi
                ;;
            tftp)
                cd /tmp
                tftp -g -r "$REMOTE_PATH" "$REMOTE_HOST"
                if [ $? -ne 0 ]; then
                    log "tftp -g -r \"$REMOTE_PATH\" \"$REMOTE_HOST\" failed!"
                    return 1
                fi
                ;;
            http|https|ftp)
                wget "$URI" -O "$LOCAL_PATH"
                if [ $? -ne 0 ]; then
                    log "wget $URI failed!"
                    return 1
                fi
                ;;
            file)
                METAFILE_PATH=$(echo $URI | sed 's,^file://,,')
                COMPONENTNAME=$(cat $METAFILE_PATH | awk -F= '$1=="ComponentName"{print $2}')
                LOCAL_PATH="$(dirname "$METAFILE_PATH")/$IMAGENAME"
                echo "METAFILE_PATH=$METAFILE_PATH"
                ;;
            *)
                log "Invalid URI $URI"
                return 1
                ;;
        esac
        update_percentage $UPDATE_PERCENT_FETCH_COMPLETE
    fi
}

update_fw() {
    # determine firmware file type
    # local componentName=$(cat $LOCAL_PATH | awk -F= '$1=="ComponentName"{print $2}')
    applytime=$(busctl get-property xyz.openbmc_project.Software.BMC.Updater \
            /xyz/openbmc_project/software/$img_obj \
            xyz.openbmc_project.Software.ApplyTime RequestedApplyTime \
            | awk '{print $2}' | tr -d '"')
    if [ -z "$COMPONENTNAME" ] ; then
        if [ -f "$(dirname "$METAFILE_PATH")/image-runtime" ] || [ -f "$(dirname "$METAFILE_PATH")/image-kernel" ]; then
            if [ -f "$(dirname "$METAFILE_PATH")/image-runtime" ]; then LOCAL_PATH="$(dirname "$METAFILE_PATH")/image-runtime"; else LOCAL_PATH="$(dirname "$METAFILE_PATH")/image-kernel"; fi
            COMPONENTNAME="bmc"
            echo "Updating image $LOCAL_PATH"
            FWTYPE=$COMPONENTNAME
            FWVER=$(get_firmware_version)
            redfish_log_fw_evt start
            ping_pong_update
            return $?
        elif [ -f "$(dirname "$METAFILE_PATH")/image-bmc" ]; then
            LOCAL_PATH="$(dirname "$METAFILE_PATH")/image-bmc" 
            COMPONENTNAME="bmc"
        elif [ -f "$(dirname "$METAFILE_PATH")/image-bios" ]; then
            LOCAL_PATH="$(dirname "$METAFILE_PATH")/image-bios" 
            COMPONENTNAME="bios"
        elif [ -f "$(dirname "$METAFILE_PATH")/image-cpld" ]; then
            LOCAL_PATH="$(dirname "$METAFILE_PATH")/image-cpld" 
            COMPONENTNAME="cpld"
        elif [ -f "$(dirname "$METAFILE_PATH")/image-pldm" ]; then
            LOCAL_PATH="$(dirname "$METAFILE_PATH")/image-pldm" 
            COMPONENTNAME="pldm"
        elif [ -f "$(dirname "$METAFILE_PATH")/image-raid" ]; then
            LOCAL_PATH="$(dirname "$METAFILE_PATH")/image-raid" 
            COMPONENTNAME="raid"
        fi    
    fi  
    FWTYPE=$COMPONENTNAME
    FWVER=$(get_firmware_version)
    redfish_log_fw_evt start
    log "Check firmware update priority"
    IsMeetsMultiFirmwareRules ${img_obj}
    if [[ "$?" = "${RET_FAILED}" ]];then
        log "Multiple firmware updates failed - priority error"
        set_requestedactivation_status None
        return "${RET_FAILED}"
    fi

    echo "Updating image $LOCAL_PATH"
    case "$COMPONENTNAME" in
        "bmc")
            log "BMC Full Flash - full SPI update request"
            bmc_full_flash
            return $?
            ;;
        "bios")
	        # TODO: Check with BIOS team, is this magic number constant?
            local magicIFWIImg=$(hexdump -s 16 -n 4 -v -e '/1 "%02x"' "$LOCAL_PATH")
            if [[ "$magicIFWIImg" = "5aa5f00f" ]]; then
                log "IFWI Full Flash - 64MB full SPI update request"
                ifwi_full_flash
                return $?
            fi
            ;;
        "cpld")
            log "BMC CPLD Flash update request"
            cpld_full_flash
            return $?
            ;;
        "pldm")
            log "PLDM update request"
            local magicPLDM=$(hexdump -n 16 -v -e '/1 "%02x"' "$LOCAL_PATH")
            if [[ "$magicPLDM" = "f018878ccb7d49439800a02f059aca02" ]]; then
                log "PLDM magic matched "
                pldm_update
                return $?
            else
                log "Unknown pldm file type Magic ${magicPLDM}"   
                return 1 
            fi
            ;;    
        "raid")
            log "RAID Firmware update request"
            raid_update
            return $?
            ;;        
        *)       
            log "Unknown component name ${componentName}"
            return 1
            ;;
    esac
}

# if this script was sourced, just return without executing anything
[ "$_" != "$0" ] && return 0 >&/dev/null

cleanup() {
    if [ $local_file -eq 0 ]; then
        # rm -rf "$(dirname "$LOCAL_PATH")"
        echo "remove called"
    fi
}

usage() {
        echo "usage: $(basename $0) uri"
        echo "       uri is something like: file:///path/to/fw"
        echo "                              tftp://tftp.server.ip.addr/path/to/fw"
        echo "                              scp://[user@]scp.server.ip.addr:/path/to/fw"
        echo "                              http[s]://web.server.ip.addr/path/to/fw"
        echo "                              ftp://[user@]ftp.server.ip.addr/path/to/fw"
        exit 1
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then usage; fi
if [ $# -eq 0 ]; then
    # set DEFURI in $HOME/.fwupd.defaults
    URI="$DEFURI"
else
    echo "path=$1"
    if [[ "$1" == *"/"* ]]; then
        URI=$1 # local file
        local_file=1 ;
        mkdir -p /tmp/updateImage;
        tar -xvf $1 -C "/tmp/updateImage";
        rm -rf $1 #clear tar file after untar it
        URI="file:///tmp/updateImage/MANIFEST";
    else
        path=$(find / -name "$1")
	URI="file://$path/MANIFEST"
        img_obj=$1
        local_file=0 ;
    fi
fi
trap cleanup EXIT

fetch_fw && update_fw || exit_fail
