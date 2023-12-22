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
SECURE_BOOT_STRAP_ENABLED=1
update=/run/initramfs/update
whitelist=/run/initramfs/whitelist
uboot_env_bin_file="uboot_env_data.bin"
NON_INTEL_PLATFORMS_MODE=1

update_percentage() {
    if [ -n "$img_obj" ]; then
        busctl set-property xyz.openbmc_project.Software.BMC.Updater \
               /xyz/openbmc_project/software/$img_obj \
               xyz.openbmc_project.Software.ActivationProgress Progress \
               y $1 || return 0
    fi
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
            #mount nv rwfs mtd partition
            mount -t jffs2 -o sync,ro mtd:rwfs /tmp/.rwfs
            #start nv sync
            systemctl start nv-sync.service
            #stop nv sync to dump overlay files to nv storage
            wait_for_log_sync
            systemctl stop nv-sync.service
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

redfish_log_fw_evt() {
    local evt=$1
    local sev=""
    local msg=""
    [ -z "$FWTYPE" ] && return
    [ -z "$FWVER" ] && return
    case "$evt" in
        start)
            update_percentage $UPDATE_PERCENT_INIT
            evt=OpenBMC.0.1.FirmwareUpdateStarted
            msg="${FWTYPE} firmware update to version ${FWVER} started."
            sev=OK
            ;;
        success)
            update_percentage $UPDATE_PERCENT_SUCCESS
            evt=OpenBMC.0.1.FirmwareUpdateCompleted
            msg="${FWTYPE} firmware update to version ${FWVER} completed successfully."
            sev=OK
            ;;
        staged)
            evt=OpenBMC.0.1.FirmwareUpdateStaged
            msg="${FWTYPE} firmware update to version ${FWVER} staged successfully."
            sev=OK
            ;;
        *) return ;;
    esac
    logger-systemd --journald <<-EOF
		MESSAGE=$msg
		PRIORITY=2
		SEVERITY=${sev}
		REDFISH_MESSAGE_ID=${evt}
		REDFISH_MESSAGE_ARGS=${FWTYPE},${FWVER}
		EOF
}

redfish_log_abort() {
    local evt=""
    local sev=""
    local msg=""
    local reason=$1
    [ -z "$FWTYPE" ] && return
    [ -z "$FWVER" ] && return
    evt=OpenBMC.0.1.FirmwareUpdateFailed
    msg="${FWTYPE} firmware update to version ${FWVER} failed: ${reason}."
    sev=Warning
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


get_requestedactivation_status() {
    local image="$1"
    if [ $local_file -eq 0 ]; then
    busctl get-property xyz.openbmc_project.Software.BMC.Updater \
            /xyz/openbmc_project/software/$image \
            xyz.openbmc_project.Software.Activation RequestedActivation \
            | awk '/s / {print $2}' | sed 's/"//g'
    fi
}

exit_fail() {
    set_activation_status Failed
    update_percentage $UPDATE_PERCENT_FAIL
    log "${FWTYPE}:${FWVER} - UPDATE_FAILED"
    exit 1
}


ifwi_full_flash() {
    # Reading the version from IFWI image(64MB) is not possible.
    # So setting FWVER to "NA".
    FWTYPE="BIOS"
    FWVER="NA"

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
        set_activation_status Failed
        update_percentage $UPDATE_PERCENT_FAIL
        return 1
    fi

    # Flash: writing to BIOS SPI device
    log "IFWI Full Flash - Starting the SPI write. It will take ~5 minutes...."
    local rc=$(mtd-util -d /dev/$mtdPart c $LOCAL_PATH 0)
    # Log Event: Update percentage and log event
    update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_COMPLETE
    if [[ "$rc" -eq 0 ]]; then
        log "IFWI Full Flash - Image update successful"
        redfish_log_fw_evt success
        update_percentage $UPDATE_PERCENT_SUCCESS
        set_activation_status Active 
        return 0
    else
        log "IFWI Full Flash - Image update failed"
        redfish_log_abort " IFWI Full Flash - Image update failed"
        set_activation_status Failed
        update_percentage $UPDATE_PERCENT_FAIL
	return 1
    fi
}

backup_uboot_env_data() {
    local mtdPart=$( cat /proc/mtd | awk '{print $1 $4}' | awk -F: '$2=="\"u-boot-env\"" {print $1}')
    local mtd_size=$(printf "%x\n" $(cat /sys/class/mtd/${mtdPart}/size))
    if test "$1" == "$NON_INTEL_PLATFORMS_MODE"; then
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
    FWTYPE="BMC"
    FWVER="NA"

    update_percentage $UPDATE_PERCENT_PRESTAGE_VERIFY_START
    # Use update script to update Firmware for non-intel platforms
    if test -x $update
    then
        check_preserv_config $NON_INTEL_PLATFORMS_MODE
        cp $LOCAL_PATH /run/initramfs/
        redfish_log_fw_evt success
        update_percentage $UPDATE_PERCENT_SUCCESS
        set_activation_status Active
        reboot
        return 0
    else

        update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_START
        local requestedactivationstate=$(get_requestedactivation_status bmc_bkup)
        if [[ "$requestedactivationstate" == "xyz.openbmc_project.Software.Activation.RequestedActivations.Active" ]]; then
            log "BMC Full Flash - Starting the SPI write on bkup CS1 spi . It will take ~8 minutes...."
            local mtdPart=$( cat /proc/mtd | awk '{print $1 $4}' | awk -F: '$2=="\"alt-bmc\"" {print $1}')
            echo "mtdPart=$mtdPart"
            if [ -z "$mtdPart" ]; then
                log "BMC Full Flash - alt-bmc mtd patition not found"
                redfish_log_abort " BMC Full Flash - Image update failed"
                set_activation_status Failed
                set_requestedactivation_status None
                update_percentage $UPDATE_PERCENT_FAIL
                return 1
            fi
            local rc=$(mtd-util -d /dev/$mtdPart c $LOCAL_PATH 0)
            # Log Event: Update percentage and log event
            if [[ "$rc" -ne 0 ]]; then
                log "BMC Full Flash - Image update failed"
                redfish_log_abort " BMC Full Flash - Image update failed"
                set_activation_status Failed
                set_requestedactivation_status None
                update_percentage $UPDATE_PERCENT_FAIL
                return 1
            fi
            update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_COMPLETE
            log "BMC Full Flash - Image update successful on bkup spi"
            redfish_log_fw_evt success
            update_percentage $UPDATE_PERCENT_SUCCESS
            set_activation_status Active 
            sleep 5
            reboot -f
        fi
        #stop nv sync
        systemctl stop nv-sync.service
        #unmount rwfs  
        umount /tmp/.rwfs

        log "BMC Full Flash - Backup u-boot-env partition"
        backup_uboot_env_data

        # Flash: writing to BMC SPI device
        log "BMC Full Flash - Starting the SPI write. It will take ~8 minutes...."
        local rc=$(mtd-util -d /dev/mtd0 c $LOCAL_PATH 0)

        # Log Event: Update percentage and log event
        update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_COMPLETE
        if [[ "$rc" -ne 0 ]]; then
            log "BMC Full Flash - Image update failed"
            redfish_log_abort " BMC Full Flash - Image update failed"
            set_activation_status Failed
            update_percentage $UPDATE_PERCENT_FAIL
            return 1
        fi
        log "BMC Full Flash - Image update successful"
        check_preserv_config
        redfish_log_fw_evt success
        update_percentage $UPDATE_PERCENT_SUCCESS
        set_activation_status Active 
        # reboot
        sleep 5
        reboot -f
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

    if test -x $update
	then
        find $(dirname "$METAFILE_PATH") -type f -name "image-*" ! -name "*.sig" -exec cp {} /run/initramfs/ \;
        reboot 
    fi
    # do a quick sanity check on the image
    if [ $(stat -c "%s" "$LOCAL_PATH") -lt 10000000 ]; then
        log "Update file "$LOCAL_PATH" seems to be too small"
        redfish_log_abort "Update file too small"
        return 1
    fi
    dtc -I dtb -O dtb "$LOCAL_PATH" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        log "Update file $LOCAL_PATH doesn't seem to be in the proper format"
        redfish_log_abort "Invalid file format"
        return 1
    fi

    # guess based on fw_env which partition we booted from
    # local BOOTADDR=$(fw_printenv bootcmd | awk '{print $2}')
    local TGT="/dev/mtd/image-a"
    # case "$BOOTADDR" in
    #     20080000) TGT="/dev/mtd/image-b"; BOOTADDR="22480000" ;;
    #     22480000) TGT="/dev/mtd/image-a"; BOOTADDR="20080000" ;;
    #     *)        TGT="/dev/mtd/image-a"; BOOTADDR="20080000" ;;
    # esac
    log "Updating $(basename $TGT) (use bootm $BOOTADDR)"
    flash_erase $TGT 0 0
    log "Writing $(stat -c "%s" "$LOCAL_PATH") bytes"
    cat "$LOCAL_PATH" > "$TGT"
    # fw_setenv "bootcmd" "bootm ${BOOTADDR}"
    wait_for_log_sync
    # stop the nv-sync.service to trigger the overlay sync and unmount before 'reboot -f'
    systemctl stop nv-sync.service
    redfish_log_fw_evt success
    update_percentage $UPDATE_PERCENT_SUCCESS
    set_activation_status Active 
    # reboot
    reboot -f
}

cpld_full_flash()
{
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
        set_activation_status Failed
        update_percentage $UPDATE_PERCENT_FAIL
        return 1
    fi
        log "CPLD Flash - Image update successful"
        update_percentage $UPDATE_PERCENT_SUCCESS
        redfish_log_fw_evt success
        set_activation_status Active
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
        return 0
}

pldm_update() {
    busctl call xyz.openbmc_project.pldm /xyz/openbmc_project/pldm/fwu \
        xyz.openbmc_project.PLDM.FWU.FWUBase StartFWUpdate s "$LOCAL_PATH"
    if [ $? -ne 0 ]; then
        log "initialising PLDM update failed"
        exit_fail
    fi
}


fetch_fw() {
    redfish_log_fw_evt start
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
                wget --no-check-certificate "$URI" -O "$LOCAL_PATH"
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
    if [ -z "$COMPONENTNAME" ] ; then
        if [ -f "$(dirname "$METAFILE_PATH")/image-runtime" ] || [ -f "$(dirname "$METAFILE_PATH")/image-kernel" ]; then
            if [ -f "$(dirname "$METAFILE_PATH")/image-runtime" ]; then LOCAL_PATH="$(dirname "$METAFILE_PATH")/image-runtime"; else LOCAL_PATH="$(dirname "$METAFILE_PATH")/image-kernel"; fi
            COMPONENTNAME="bmc"
            echo "Updating image $LOCAL_PATH"
            ping_pong_update
            return 0
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
        fi    
    fi  
    echo "Updating image $LOCAL_PATH"
    case "$COMPONENTNAME" in
        "bmc")
            log "BMC Full Flash - full SPI update request"
            bmc_full_flash
            ;;
        "bios")
	        # TODO: Check with BIOS team, is this magic number constant?
            local magicIFWIImg=$(hexdump -s 16 -n 4 -v -e '/1 "%02x"' "$LOCAL_PATH")
            if [[ "$magicIFWIImg" = "5aa5f00f" ]]; then
                log "IFWI Full Flash - 64MB full SPI update request"
                ifwi_full_flash
                return 0
            fi
            ;;
        "cpld")
            log "BMC CPLD Flash update request"
            cpld_full_flash
            ;;
        "pldm")
            log "PLDM update request"
            local magicPLDM=$(hexdump -n 16 -v -e '/1 "%02x"' "$LOCAL_PATH")
            if [[ "$magicPLDM" = "f018878ccb7d49439800a02f059aca02" ]]; then
                log "PLDM magic matched "
                pldm_update
                return 0
            else
                log "Unknown pldm file type Magic ${magicPLDM}"   
                return 1 
            fi
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
