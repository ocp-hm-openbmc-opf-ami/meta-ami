#!/bin/bash

VER=$(grep '^VERSION_ID=' /etc/os-release | sed 's/[^=]*=\([^-]*\)-.*/\1/')

log() {
    echo "$@"
}

FWTYPE=""
FWVER=""
UPDATE_PERCENT_INIT=0
UPDATE_PERCENT_FETCH_START=10
UPDATE_PERCENT_FETCH_COMPLETE=30
UPDATE_PERCENT_PRESTAGE_VERIFY_START=40
UPDATE_PERCENT_PRESTAGE_VERIFY_COMPLETE=50
UPDATE_PERCENT_FLASH_OR_STAGE_START=60
UPDATE_PERCENT_FLASH_OR_STAGE_COMPLETE=95
UPDATE_PERCENT_SUCCESS=100
UPDATE_PERCENT_FAIL=100

update_percentage() {
    if [ -n "$img_obj" ]; then
        busctl set-property xyz.openbmc_project.Software.BMC.Updater \
               /xyz/openbmc_project/software/$img_obj \
               xyz.openbmc_project.Software.ActivationProgress Progress \
               y $1 || return 0
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

disable_me_sensors()
{
    busctl tree xyz.openbmc_project.IpmbSensor --list | \
        grep "temperature/" | while read path; do

        busctl set-property xyz.openbmc_project.IpmbSensor $path \
            xyz.openbmc_project.State.Decorator.Availability Available b 0 \
            || log "failed to disable $path"
    done
}

enable_me_sensors()
{
    busctl tree xyz.openbmc_project.IpmbSensor --list | \
        grep "temperature/" | while read path; do

        busctl set-property xyz.openbmc_project.IpmbSensor $path \
            xyz.openbmc_project.State.Decorator.Availability Available b 1 \
            || log "failed to enable $path"
    done
}


sps_fw_req() {
    local bus=1
    local lun=0
    local netfn="$1"
    local cmd="$2"
    shift; shift # remove $1 $2
    local data="$@"
    local array_data=""
    local rsp=""
    local ipmbok=0
    local ipmiok=0
    local RPL='.*struct { int32 \([0-9]\+\) byte \([0-9]\+\) byte \([0-9]\+\) byte \([0-9]\+\) byte \([0-9]\+\) array[^[]*\[\([^]]*\)].*'
    for D in $data; do
        if [ -z "$array_data" ]; then
            array_data="array:byte:0x${D}"
        else
            array_data="${array_data},0x${D}"
        fi
    done;
    [ -z "$array_data" ] && array_data="array:byte:"
    rsp=$(dbus-send --system --print-reply \
        --dest=xyz.openbmc_project.Ipmi.Channel.Ipmb \
        --type=method_call "/xyz/openbmc_project/Ipmi/Channel/Ipmb" \
        "org.openbmc.Ipmb.sendRequest" "byte:0x${bus}" "byte:0x${netfn}" \
        "byte:0x${lun}" "byte:0x${cmd}" "$array_data") || \
            return 1 # caller will log with a more specific message
    ipmbok=$(echo $rsp | sed "s/${RPL}/\1/")
    ipmiok=$(echo $rsp | sed "s/${RPL}/\5/")
    [ "$ipmbok" != "0" ] && return $ipmbok
    [ "$ipmiok" != "0" ] && return $ipmiok
    echo $rsp | sed "s/${RPL}/\6/"
}

IGNORE_PCH_FAILURES=0
[ -e /tmp/ignore_pch_failures ] && IGNORE_PCH_FAILURES=1

ignore_pch_failures() {
    [ $IGNORE_PCH_FAILURES -eq 1 ]
}

seamless_abort_on_pch_errors() {
    if ignore_pch_failures; then
        return;
    fi
    seamless_abort "$@"
}

PFR_BUS=4
PFR_ADDR=0x38
PFR_ID_REG=0x00
PFR_STATE_REG=0x03
PFR_PROV_REG=0x0a
PFR_INTENT_REG=0x13
PFR_INTENT2_REG=0x62
if [ "$VER" = "wht" ]; then
PFR_SEAMLESS_INTENT_REG=$PFR_INTENT_REG
UPD_INTENT_SEAMLESS=0x20
PFR_UPDATE_DYNAMIC_MASK=0
BMC_UPD_ACK_VAL=
else # egs and later
PFR_SEAMLESS_INTENT_REG=$PFR_INTENT2_REG
UPD_INTENT_SEAMLESS=0x81
PFR_UPDATE_DYNAMIC_MASK=64
BMC_UPD_ACK_VAL=0
fi
MBOX_C=12
MBOX_D=13

pfr_read() {
    [ $# -ne 1 ] && return 1
    local reg=$1
    i2cget -y $PFR_BUS $PFR_ADDR $reg 2>/dev/null
}

pfr_write() {
    [ $# -ne 2 ] && return 1
    local reg=$1
    local val=$2
    i2cset -y $PFR_BUS $PFR_ADDR $reg $val >&/dev/null
}

mbox_read() {
    local box=$1
    local val=$(busctl get-property xyz.openbmc_project.Host.Misc.Manager \
                /xyz/openbmc_project/misc/mailbox/$box \
                xyz.openbmc_project.Misc.Mailbox Value 2>/dev/null \
                | cut -d " " -f 2)
    printf " 0x%.2X\n" "$val"
}

mbox_setbit() {
    local box=$1
    local bit=$2
    local v=$(mbox_read $box) || return 1
    v=$((v | (1 << bit) ))
    busctl set-property xyz.openbmc_project.Host.Misc.Manager \
        /xyz/openbmc_project/misc/mailbox/$box \
        xyz.openbmc_project.Misc.Mailbox Value y "$v" >&/dev/null
}

mbox_clearbit() {
    local box=$1
    local bit=$2
    local v=$(mbox_read $box) || return 1
    v=$((v & ~(1 << bit) ))
    busctl set-property xyz.openbmc_project.Host.Misc.Manager \
        /xyz/openbmc_project/misc/mailbox/$box \
        xyz.openbmc_project.Misc.Mailbox Value y "$v" >&/dev/null
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

# host powered off is a 'forced-update' mode where host-complex
# errors are ignored for seamless updates
host_powered_on() {
    local host_state=$(busctl get-property \
        xyz.openbmc_project.State.Host /xyz/openbmc_project/state/host0 \
        xyz.openbmc_project.State.Host CurrentHostState)
    case "$host_state" in
        *HostState.Running*) ;;
        *HostState.Off*)
            # host is off, ignoring PCH errors; PCH flash might be broken
            IGNORE_PCH_FAILURES=1
            log "${FWTYPE}:${FWVER} - HOST_POWERED_OFF; ignoring PCH errors"
            return 0
            ;;
        *) return 1;;
    esac
    local os_state=$(busctl get-property \
        xyz.openbmc_project.State.Host /xyz/openbmc_project/state/os \
        xyz.openbmc_project.State.OperatingSystem.Status OperatingSystemState)
    case "$os_state" in
        *Standby*)
            # check to see that host has been powered on for required time
            local PWR_ON_TIME=120
            local last_change=$(busctl get-property \
                xyz.openbmc_project.State.Chassis \
                /xyz/openbmc_project/state/chassis0 \
                xyz.openbmc_project.State.Chassis LastStateChangeTime \
                | awk '{print $2}')
            last_change=$((last_change / 1000 + PWR_ON_TIME))
            if [ "$last_change" -gt $(date +%s) ]; then
                log "${FWTYPE}:${FWVER} - HOST_NOT_BOOTED; refusing to update"
                return 1
            fi
            return 0
            ;;
        *) return 1;;
    esac
    return 1
}

CHASSIS_BUTTONS_SERVICE="xyz.openbmc_project.Chassis.Buttons"
BUTTON_PATH="/xyz/openbmc_project/chassis/buttons"
BUTTON_IFACE="xyz.openbmc_project.Chassis.Buttons"
FP_BUTTONS="power reset nmi"
declare -A BUTTON=()
get_front_panel_buttons() {
    local v=""
    for b in $FP_BUTTONS; do
        v=$(busctl get-property $CHASSIS_BUTTONS_SERVICE \
            $BUTTON_PATH/$b $BUTTON_IFACE ButtonMasked)
        BUTTON[$b]="$v"
    done
}

disable_front_panel_buttons() {
    get_front_panel_buttons
    for b in $FP_BUTTONS; do
        busctl set-property $CHASSIS_BUTTONS_SERVICE \
            $BUTTON_PATH/$b $BUTTON_IFACE ButtonMasked b true
    done
}

restore_front_panel_buttons() {
    for b in $FP_BUTTONS; do
        busctl set-property $CHASSIS_BUTTONS_SERVICE \
            $BUTTON_PATH/$b $BUTTON_IFACE ButtonMasked ${BUTTON[$b]}
    done
}

exit_fail() {
    set_activation_status Failed
    update_percentage $UPDATE_PERCENT_FAIL
    log "${FWTYPE}:${FWVER} - SEAMLESS_UPDATE_FAILED"
    exit 1
}

lock_pch_flash() {
    mbox_setbit $MBOX_D 0 >&/dev/null
    if [ $? -ne 0 ]; then
        log "failed to set intent-to-write mailbox"
        return 1
    fi
    # poll for bios no nv mode
    for ((i=0; i<100; i++)); do
        b=$(mbox_read $MBOX_C)
        [ $(($b & 0x01)) -eq 0 ] && break
        sleep .1
    done
    return $(($b & 0x01))
}

unlock_pch_flash() {
    mbox_clearbit $MBOX_D 0 >&/dev/null
    return $?
}

seamless_init() {
    disable_front_panel_buttons
    # trigger sps recovery mode
    disable_me_sensors
    sps_fw_req 2e df 57 1 0 1 >/dev/null 2>&1 || \
        seamless_abort_on_pch_errors "${FWTYPE}:${FWVER} - SPS_RECOVERY_MODE_FAILED - Failed request to enter ME recovery mode"
    sleep 2
    # poll for sps recovery mode
    local b=0
    local m=0
    for ((i=0; i<10; i++)); do
        m=$(sps_fw_req 6 1 2>/dev/null)
        if [ $? -ne 0 ]; then
            seamless_abort_on_pch_errors "${FWTYPE}:${FWVER} - SPS_RECOVERY_MODE_FAILED - Failed checking for ME recovery mode"
            # if seamless_abort_on_pch_errors returns, it means the error was ignored
            # don't try again nine more times
            break;
        fi
        b=$(echo $m | awk '{print $15}')
        [ "$b" == '00' ] && break
        sleep 1
    done
    [ "$b" == '00' ] || \
        seamless_abort_on_pch_errors "${FWTYPE}:${FWVER} - SPS_RECOVERY_MODE_FAILED"
    # wait another 3 seconds for the ME to finish booting
    # Alternative is to have cpld expose gpio from ME via mailbox
    sleep 3
    log "${FWTYPE}:${FWVER} - SPS_RECOVERY_MODE_ENTERED"
    # trigger bios no nv mode
    lock_pch_flash || \
        seamless_abort_on_pch_errors "${FWTYPE}:${FWVER} - SPI_BLOCK_FAILED - Lock PCH flash timeout"
    # trigger bmc no nv mode
    systemctl stop nv-sync.service || \
        seamless_abort "${FWTYPE}:${FWVER} - SPI_BLOCK_FAILED - BMC nv-sync service failed to stop"
}

seamless_fini() {
    # exit bmc no nv mode
    systemctl start nv-sync.service || log "failed to start nv-sync"
    # check sps for recovery mode && reset
    log "${FWTYPE}:${FWVER} - SPS_RESET_INITIATED"
    if sps_fw_req 6 2 >&/dev/null; then
        log "${FWTYPE}:${FWVER} - SPS_RESET_OK"
    else
        log "${FWTYPE}:${FWVER} - SPS_RESET_FAILED"
    fi
    # check if bios no nv mode && release
    unlock_pch_flash || \
        log "${FWTYPE}:${FWVER} - SPI_UNBLOCK_FAILED - failed to clear intent-to-write mailbox"
    enable_me_sensors
    restore_front_panel_buttons
    rm -f /tmp/nowatchdog
}

seamless_abort() {
    local msg="$1"
    log "$msg"

    seamless_fini

    # log seamless update error
    redfish_log_abort "$msg"
    exit_fail
}

seamless_complete() {
    seamless_fini
    redfish_log_fw_evt success
    set_activation_status Active
    log "${FWTYPE}:${FWVER} - SEAMLESS_UPDATE_COMPLETE"
    return 0
}

seamless_update_flow() {
    if ! host_powered_on; then
        log "${FWTYPE}:${FWVER} - HOST_POWERED_OFF"
        redfish_log_abort "Target power state off; turn target on and try again"
        return 1
    fi
    log "${FWTYPE}:${FWVER} - BMC_BEGIN_CAPSULE_STAGING"
    flash_erase $TGT $erase_offset $blk_cnt
    local img_sz=$(stat -c "%s" "$LOCAL_PATH")
    log "Writing $img_sz bytes"
    # stage the image
    dd bs=4k seek=$(($erase_offset / 0x1000)) if=$LOCAL_PATH of=$TGT
    log "${FWTYPE}:${FWVER} - BMC_CAPSULE_STAGED"
    sync
    # Read back the staged image to authenticate it
    local img_sz_rd=$(((img_sz + 0xfff) / 0x1000))
    dd bs=4k skip=$(($erase_offset / 0x1000)) if=$TGT count=$img_sz_rd of="${LOCAL_PATH}.check"
    truncate -s $img_sz "${LOCAL_PATH}.check"
    /usr/bin/mtd-util p a "${LOCAL_PATH}.check"
    local verified=$?
    rm -f "${LOCAL_PATH}.check"
    if [ $verified -eq 0 ]; then
        log "${FWTYPE}:${FWVER} - BMC_CAPSULE_AUTHENTICATED"
    else
        log "${FWTYPE}:${FWVER} - BMC_INVALID_CAPSULE - authentication failed"
        redfish_log_abort "${FWTYPE}:${FWVER} - Image verification failed"
        return 1
    fi
    set_activation_status Staged

    seamless_init || seamless_abort
    # critical workaround; do not do this for now
    #if [ $PFR_UPDATE_DYNAMIC_MASK -ne 0 ]; then
        # log "${FWTYPE}:${FWVER} - UPDATE_DYNAMIC_MASK"
        # pfr_write $PFR_INTENT_REG $PFR_UPDATE_DYNAMIC_MASK
    #fi
    if ! host_powered_on; then
        log "${FWTYPE}:${FWVER} - HOST_NOT_BOOTED"
        seamless abort "${FWTYPE}:${FWVER} - HOST_NOT_BOOTED: Target in reset or not fully booted; try again later"
    fi
    pfr_write $PFR_SEAMLESS_INTENT_REG $upd_intent_val
    log "${FWTYPE}:${FWVER} - CPLD_SPI_OWNED"
    local cpld_state=$(pfr_read 0x03)
    while :; do
        [ "$cpld_state" == "0x14" ] && break
        [ "$cpld_state" == "0x15" ] && break
        cpld_state=$(pfr_read 0x03)
    done
    while :; do
        cpld_state=$(pfr_read 0x03)
        [ "$cpld_state" == "0x14" ] || break
        sleep 2
    done

    # inform CPLD that BMC is finished waiting
    if [ -n "$BMC_UPD_ACK_VAL" ]; then
        pfr_write $PFR_SEAMLESS_INTENT_REG $BMC_UPD_ACK_VAL
    fi

    if [ "$cpld_state" != "0x15" ]; then
        seamless_abort "${FWTYPE}:${FWVER} - CPLD_COPY_FAILED"
        return $?
    fi
    local err_major=$(pfr_read 0x08)
    local err_minor=$(pfr_read 0x09)
    if [ "$err_major" == "0x03" ]; then
        seamless_abort "${FWTYPE}:${FWVER} - CPLD_COPY_FAILED: ${err_major}/${err_minor}"
        return $?
    fi
    log "${FWTYPE}:${FWVER} - CPLD_COPY_COMPLETED"
    seamless_complete
    return $?
}

bios_supports_seamless() {
    # check is only valid on egs+
    [ "$VER" = "wht" ] && return 0

    local v=$(mbox_read $MBOX_C) || return 1
    # MBOX_C[1]: 1 == BIOS supports seamless
    # MBOX_C[2]: 1 == BIOS has initialized MBOX_C
    [ $(($v & 0x06)) -eq 6 ] && return 0
    return 1;
}

seamless_update() {
    if ! bios_supports_seamless; then
        log "Attempted seamless update not supported by BIOS"
        return 1
    fi
    touch /tmp/nowatchdog
    seamless_update_flow
    local ret=$?
    local id=$(basename $(dirname "${LOCAL_PATH}"))
    local fwpath="/xyz/openbmc_project/software/${id}"
    local del_intf="xyz.openbmc_project.Object.Delete"

    # seamless update versions should be reported via normal per-part
    # mechanisms; no need to keep the old version interfaces around
    busctl call xyz.openbmc_project.Software.Version "$fwpath" "$del_intf" Delete
    busctl call xyz.openbmc_project.Software.BMC.Updater "$fwpath" "$del_intf" Delete
    rm -f /tmp/nowatchdog
    return $ret
}

# only valid response for wht
pfr_seamless_mode() {
    # check for 0xde in register file 0
    local id=$(pfr_read $PFR_ID_REG) || return 1
    [ "$id" == "0xde" ] || return 1
    local state=$(pfr_read $PFR_STATE_REG) || return 1
    local prov=$(pfr_read $PFR_PROV_REG) || return 1
    prov=$((prov & 0x20))
    [ "$prov" == "0" ] || return 1
    case "$state" in
    0x09|0x15) return 0;;
    esac
    return 1
}

pfr_active_update() {
    local factory_reset=""
    local recovery_offset=0x2a00000
    update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_START
    # disable systemd watchdog
    touch /tmp/nowatchdog

    systemctl stop nv-sync.service || \
        log "BMC NV sync failed to stop"
    if [ ! -e /usr/share/pfr ]; then
        factory_reset="-r"
        mtd-util pfr stage $LOCAL_PATH $recovery_offset
    fi
    mtd-util $factory_reset pfr write $LOCAL_PATH
    update_percentage $UPDATE_PERCENT_FLASH_OR_STAGE_COMPLETE
    redfish_log_fw_evt success
    set_activation_status Staged
    if [ -e /usr/share/pfr ]; then
        # exit bmc no nv mode
        systemctl start nv-sync.service || log "failed to start nv-sync"
        wait_for_log_sync
    fi
    # stop the nv-sync.service to trigger the overlay sync and unmount before 'reboot -f'
    systemctl stop nv-sync.service
    reboot -f
}

pfr_staging_update() {
    log "Updating $(basename $TGT)"
    flash_erase $TGT $erase_offset $blk_cnt
    log "Writing $(stat -c "%s" "$LOCAL_PATH") bytes"
    # cat "$LOCAL_PATH" > "$TGT"
    dd bs=4k seek=$(($erase_offset / 0x1000)) if=$LOCAL_PATH of=$TGT 2>/dev/null

    # remove the updated image from /tmp
    rm -f $LOCAL_PATH
    redfish_log_fw_evt staged
    set_activation_status Staged
    log "Writing value:$upd_intent_val to PFR update intent register:$PFR_INTENT_REG"
    wait_for_log_sync
    systemctl stop nv-sync.service

    # write to PFRCPLD about BMC update intent.
    pfr_write $PFR_INTENT_REG $upd_intent_val
    systemctl start nv-sync.service
}

pfr_inactive_mode() {
    # check for 0xde in register file 0
    local id=$(pfr_read $PFR_ID_REG) || return 1
    [ "$id" == "0xde" ] || return 1
    return 0
}

pfr_active_mode() {
    # check for 0xde in register file 0
    local id=$(pfr_read $PFR_ID_REG) || return 1
    [ "$id" == "0xde" ] || return 1
    local prov=$(pfr_read $PFR_PROV_REG) || return 1
    prov=$((prov & 0x20))
    [ $prov -eq 0 ] && return 1
    return 0
}

smm_update() {
    # if host is powered off, allow smm updates, otherwise check policy
    if host_powered_on; then
        # check control bit, failure to read means we reject attempts
        local v=$(mbox_read $MBOX_C) || return 1
        # if bit is set, smm updates are not OK
        [ $(($v & 0x08)) -eq 0 ] || return 1
    fi

    status=$(busctl call xyz.openbmc_project.MMBI_0.Seamless /xyz/openbmc_project/smm_runtime_update xyz.openbmc_project.smm_runtime_update StartFwUpdate s $LOCAL_PATH)
}

bmc_ras_offload_enabled() {
    local ras_features=$(busctl get-property \
            xyz.openbmc_project.HostErrorMonitor \
            /xyz/openbmc_project/host_error_monitor/operational_status \
            xyz.openbmc_project.HostErrorMonitor.OpStatus enabledRasFeatures \
            | cut -d " " -f 2)
    # force ras_features to be an integer
    ras_features=$((ras_features + 0))
    # if ras_features is zero, no RAS offload is active
    [ "$ras_features" -ne 0 ]
    return $?
}

allow_os_transparent_update() {
    # if host is powered off, allow any update
    host_powered_on || return 0
    # check control bit, failure to read means we reject attempts
    local v=$(mbox_read $MBOX_C) || return 1
    # if bit is clear, OS transparent updates are OK
    [ $(($v & 0x08)) -eq 0 ] && return 0
    # bit is set, selectively reject images that are OS transparent updates
    local img_type="$1"
    local fv_type=""
    if [ "$img_type" == "04" ]; then
        # if BMC is hosting any RAS offloading, updates are restricted
        bmc_ras_offload_enabled && return 1
        return 0 # BMC update OK
    elif [ "$img_type" == "05" ]; then
        # need to check what kind of seamless update
        # fm type is at offset 0x80a
        fv_type=$(hexdump -s 0x80a -n 1 -e '/1 "%02x\n"' $LOCAL_PATH)
        case "$fv_type" in
            00) return 0;; # BIOS
            01) return 1;; # SPS FW RCV
            02) return 0;; # uCode 1
            03) return 0;; # uCode 2
            04) return 0;; # uCode 3
            05) return 0;; # uCode 4
            06) return 0;; # uCode 5
            07) return 0;; # uCode 6
            08) return 0;; # uCode 7
            09) return 0;; # uCode 8
            0a) return 1;; # SPS FW OPR
            0b) return 0;; # uCode 9
            0c) return 0;; # utility capsule 1
            0d) return 0;; # utility capsule 2
            *) return 0;; ## all other firmware
        esac
    fi
    return 0
}

blk0blk1_update() {
    # PFR-style image update section
    # read the image type from the uploaded image
    # Byte at location 0x8 gives image type
    TGT="/dev/mtd/image-stg"
    img_type=$(hexdump -s 8 -n 1 -e '/1 "%02x\n"' $LOCAL_PATH)
    log "image-type=$img_type"

    if [ $local_file -eq 0 ]; then
        img_type_str=$(busctl get-property xyz.openbmc_project.Software.BMC.Updater /xyz/openbmc_project/software/$img_obj xyz.openbmc_project.Software.Version Purpose | cut -d " " -f 2 | cut -d "." -f 6 | sed 's/.\{1\}$//')
        img_target=$(busctl get-property xyz.openbmc_project.Software.BMC.Updater /xyz/openbmc_project/software/$img_obj xyz.openbmc_project.Software.Activation RequestedActivation | cut -d " " -f 2| cut -d "." -f 6 | sed 's/.\{1\}$//')
    else
        img_type_str='BMC'
        img_target='Active'
    fi

    apply_time=$(busctl get-property xyz.openbmc_project.Settings /xyz/openbmc_project/software/apply_time xyz.openbmc_project.Software.ApplyTime RequestedApplyTime | cut -d " " -f 2 | cut -d "." -f 6 | sed 's/.\{1\}$//')

    clear_cfg=$(busctl get-property xyz.openbmc_project.Software.BMC.Updater /xyz/openbmc_project/software xyz.openbmc_project.Software.ApplyOptions ClearConfig | cut -d " " -f 2 | cut -d "." -f 6)

    log "image-name=$img_type_str"
    log "image-target=$img_target"
    log "apply_time=$apply_time"
    log "clear_cfg=$clear_cfg"

    case "$img_type" in
    04)
        if [ "$img_type_str" == 'BMC' ]; then
            # BMC image - max size 32MB
            log "BMC firmware image"
            img_size=33554432
            if [ "$img_target" == 'StandbySpare' ]; then
                upd_intent_val=0x10
            else
                upd_intent_val=0x08
            fi
            erase_offset=0
            FWTYPE="BMC"
            FWMAJOR=$(hexdump -s 2054 -n 1 -e '/1 "%02u\n"' $LOCAL_PATH)
            FWMINOR=$(hexdump -s 2055 -n 1 -e '/1 "%02u\n"' $LOCAL_PATH)
            FWVER="$FWMAJOR.$FWMINOR"
            redfish_log_fw_evt start
        else
            # log error the image selected for update is not same as downloaded.
            log "Mismatch: image selected for update and image parsed are different"
            redfish_log_abort "Invalid image file - Type mismatch"
            return 1
        fi
        ;;
    00)
        if [ "$img_type_str" == 'Other' ]; then
            log "CPLD firmware image"
            # CPLD image- max size 1MB
            img_size=1048576
            if [ "$img_target" == 'StandbySpare' ]; then
                upd_intent_val=0x20
            else
                upd_intent_val=0x04
            fi
            erase_offset=0x3000000
            FWTYPE="CPLD"
            FWVER="${RANDOM}-fixme"
            redfish_log_fw_evt start
        else
            # log error the image selected for update is not same as downloaded.
            log "Mismatch: image selected for update and image parsed are different"
            redfish_log_abort "Invalid image file - Type mismatch"
            return 1
        fi
        ;;
    02)
        if [ "$img_type_str" = 'Host' ]; then
            # BIOS image- max size 16MB
            log "BIOS firmware image"
            img_size=16777216
            if [ "$img_target" == 'StandbySpare' ]; then
                upd_intent_val=0x02
            else
                upd_intent_val=0x01
                if [ "$clear_cfg" == 'true' ]; then
                    upd_intent_val=$(( "$upd_intent_val"|0x40 ))
                fi
            fi
            erase_offset=0x2000000
            # TODO: parse out the fwtype and fwver once that is specified
            FWTYPE="BIOS"
            FWMAJOR=$(hexdump -s 2054 -n 1 -e '/1 "%02u\n"' $LOCAL_PATH)
            FWMINOR=$(hexdump -s 2055 -n 1 -e '/1 "%02u\n"' $LOCAL_PATH)
            FWVER="$FWMAJOR.$FWMINOR"
            redfish_log_fw_evt start
        else
            # log error the image selected for update is not same as downloaded.
            log "Mismatch: image selected for update and image parsed are different"
            redfish_log_abort "Invalid image file - Type mismatch"
            return 1
        fi
        ;;
    05)
        # Seamless PCH image- max size 16MB
        log "Seamless PCH firmware image"
        if [ -n "$apply_time" ]; then
            log "Ignoring apply_time for seamless update"
            apply_time=""
        fi
        if [ -n "$clear_cfg" ]; then
            log "Ignoring clear_cfg for seamless update"
            clear_cfg=""
        fi

        img_size=16777216
        upd_intent_val=$UPD_INTENT_SEAMLESS
        erase_offset=0x2000000
        # TODO: parse out the fwtype and fwver once that is specified
        S=$(stat -c '%s' "$LOCAL_PATH")
        S=$((S / 1024))
        if [ $S -gt 4096 ]; then
            FWTYPE="Seamless BIOS"
        elif [ $S -gt 1024 ]; then
            FWTYPE="Seamless ME"
        elif [ $S -gt 16 ]; then
            FWTYPE="Seamless uCode"
        else
            FWTYPE="Seamless <FWTYPE unknown>"
        fi
        FWMAJOR=$(hexdump -s 2054 -n 1 -e '/1 "%02u\n"' $LOCAL_PATH)
        FWMINOR=$(hexdump -s 2055 -n 1 -e '/1 "%02u\n"' $LOCAL_PATH)
        FWVER="$FWMAJOR.$FWMINOR"
        redfish_log_fw_evt start
        ;;
    06)
        if [ "$img_type_str" == 'Other' ]; then
            log "AFM image"
            # AFM image- max size 128KB
            img_size=131072
            if [ "$img_target" == 'StandbySpare' ]; then
                upd_intent_val=0x04
            else
                upd_intent_val=0x02
            fi
            PFR_INTENT_REG=$PFR_INTENT2_REG
            erase_offset=0
            FWTYPE="AFM"
            #2054 is the offset where Major FW version resides
            FWMAJOR=$(hexdump -s 2054 -n 1 -e '/1 "%02u\n"' $LOCAL_PATH)
            #2055 is the offset where Minor FW version resides
            FWMINOR=$(hexdump -s 2055 -n 1 -e '/1 "%02u\n"' $LOCAL_PATH)
            FWVER="$FWMAJOR.$FWMINOR"
            redfish_log_fw_evt start
        else
            # log error the image selected for update is not same as downloaded.
            log "Mismatch: image selected for update and image parsed are different"
            redfish_log_abort "Invalid image file - Type mismatch"
            return 1
        fi
        ;;
    07)
        if [ "$img_type_str" == 'Other' ]; then
            log "Composite CPLD image"
            # CPLD image- max size 2MB
            img_size=2097152
            upd_intent_val=0x16
            PFR_INTENT_REG=$PFR_INTENT2_REG
	    erase_offset=0x3200000
            FWTYPE="CPLD"
            FWMAJOR=$(hexdump -s 2054 -n 1 -e '/1 "%02u\n"' $LOCAL_PATH)
            FWMINOR=$(hexdump -s 2055 -n 1 -e '/1 "%02u\n"' $LOCAL_PATH)
            FWVER="$FWMAJOR.$FWMINOR"
            FWMAJORCPU=$(hexdump -s 5126 -n 1 -e '/1 "%02u\n"' $LOCAL_PATH)
            FWMINORCPU=$(hexdump -s 5127 -n 1 -e '/1 "%02u\n"' $LOCAL_PATH)
            log "CPU CPLD VERSION=$FWMAJORCPU.$FWMINORCPU"
            FWMAJORSCM=$(hexdump -s 386054 -n 1 -e '/1 "%02u\n"' $LOCAL_PATH)
            FWMINORSCM=$(hexdump -s 386055 -n 1 -e '/1 "%02u\n"' $LOCAL_PATH)
            log "SCM CPLD VERSION=$FWMAJORSCM.$FWMINORSCM"
            FWMAJORDEBUG=$(hexdump -s 766982 -n 1 -e '/1 "%02u\n"' $LOCAL_PATH)
            FWMINORDEBUG=$(hexdump -s 766983 -n 1 -e '/1 "%02u\n"' $LOCAL_PATH)
            log "DEBUG CPLD VERSION=$FWMAJORDEBUG.$FWMINORDEBUG"
            redfish_log_fw_evt start

        else
            # log error the image selected for update is not same as downloaded.
            log "Mismatch: image selected for update and image parsed are different"
            redfish_log_abort "Invalid image file - Type mismatch"
            return 1
        fi
        ;;	
    *)
        log "Unknown image type ${img_type}"
        return 1
        ;;
    esac

    update_percentage $UPDATE_PERCENT_PRESTAGE_VERIFY_START
    # For deferred updates
    if [ "$apply_time" == 'OnReset' ]; then
        upd_intent_val=$(( "$upd_intent_val"|0x80 ))
    fi

    # do a quick sanity check on the image
    if [ $(stat -c "%s" "$LOCAL_PATH") -gt $img_size ]; then
        log "Update file "$LOCAL_PATH" is bigger than the supported image size"
        redfish_log_abort "update file is bigger than the supported image size"
        return 1
    fi
    blk_cnt=$((img_size / 0x10000))

    log "Verify the image"
    if /usr/bin/mtd-util p a $LOCAL_PATH
    then
        log "Pre-staging image verification successful"
        update_percentage $UPDATE_PERCENT_PRESTAGE_VERIFY_COMPLETE
    else
        log "${FWTYPE}:${FWVER} - BMC_INVALID_CAPSULE - authentication failed"
        redfish_log_abort "Image verification failed"
        return 1
    fi

    local pfr_img_type_cpld='00'
    local pfr_img_type_pch_upd='02'
    local pfr_img_type_bmc_upd='04'
    local pfr_img_type_seamless='05'
    local pfr_img_type_afm='06'
    local pfr_img_type_cmpst_cpld='07'

    if [ "$VER" = "wht" ]; then
        if pfr_active_mode; then
            # pfr enforcing mode; any b0b1 image type
            pfr_staging_update
        elif pfr_seamless_mode; then
            if [ "$img_type" == "$pfr_img_type_seamless" ]; then
                seamless_update
                return $?
            elif [ "$img_type" == "$pfr_img_type_bmc_upd" ]; then
                # legacy mode; pfr is not present but we got a pfr image
                pfr_active_update
            else
                # error; wrong image type for this state
                log "Seamless is active; cowardly refusing to process invalid image"
                return 1;
            fi
        elif [ "$img_type" == "$pfr_img_type_bmc_upd" ]; then
            # legacy mode; pfr is not present but we got a pfr image
            log "Updating BMC active firmware- PFR unprovisioned mode"
            pfr_active_update
        else
            # error; pfr is not present but we got a pfr image,
            # an invalid image, or nonBMC image
            log "PFR inactive or invalid image type:${img_type}, cowardly refusing to process image"
            redfish_log_abort "PFR inactive or invalid image type"
            return 1
        fi
    else
        # check for OS transparent updates
        if ! allow_os_transparent_update "$img_type"; then
            log "${FWTYPE}:${FWVER} - BMC_ENFORCE_OS_CONTROL - OS transparent update rejected by OS control"
            return 1
        fi
        # pfr enforcing mode; any b0b1 image type
        if pfr_active_mode; then
            # full images are staged directly
            if [ "$img_type" == "$pfr_img_type_cpld" ] || \
                [ "$img_type" == "$pfr_img_type_afm" ] || \
                [ "$img_type" == "$pfr_img_type_pch_upd" ] || \
                [ "$img_type" == "$pfr_img_type_bmc_upd" ] || \
		[ "$img_type" == "$pfr_img_type_cmpst_cpld" ]; then
                pfr_staging_update
                return $?
            # seamless images need to follow a specified flow
            elif [ "$img_type" == "$pfr_img_type_seamless" ]; then
                seamless_update
                return $?
            else
                # error; wrong image type for this state
                log "PFR is active; cowardly refusing to process invalid image"
                return 1;
            fi
        # seamless images need to follow a specified flow
        elif [ "$img_type" == "$pfr_img_type_seamless" ]; then
            if pfr_inactive_mode; then
                seamless_update
                return $?
            else
                # error; wrong image type for this state
                log "PFR is not available; cowardly refusing to process seamless image"
                return 1;
            fi
        elif [ "$img_type" == "$pfr_img_type_bmc_upd" ]; then
            # legacy mode; pfr is not present but we got a pfr image
            log "Updating BMC active firmware; PFR unprovisioned mode"
            pfr_active_update
            return $?
        else
            # error; pfr is not present but we got a pfr image,
            # an invalid image, or nonBMC image
            log "PFR inactive or invalid image type:${img_type}, cowardly refusing to process image"
            redfish_log_abort "PFR inactive or invalid image type"
            return 1
        fi
    fi
}

ping_pong_update() {
    # if some one tries to update with non-PFR on PFR image
    # just exit
    if [ -e /usr/share/pfr ]; then
        log "Update exited as non-PFR image is tried onto PFR image"
        redfish_log_abort "non-PFR image is tried onto PFR image"
        return 1
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
    local BOOTADDR=$(fw_printenv bootcmd | awk '{print $2}')
    local TGT="/dev/mtd/image-a"
    case "$BOOTADDR" in
        20080000) TGT="/dev/mtd/image-b"; BOOTADDR="22480000" ;;
        22480000) TGT="/dev/mtd/image-a"; BOOTADDR="20080000" ;;
        *)        TGT="/dev/mtd/image-a"; BOOTADDR="20080000" ;;
    esac
    log "Updating $(basename $TGT) (use bootm $BOOTADDR)"
    flash_erase $TGT 0 0
    log "Writing $(stat -c "%s" "$LOCAL_PATH") bytes"
    cat "$LOCAL_PATH" > "$TGT"
    fw_setenv "bootcmd" "bootm ${BOOTADDR}"
    redfish_log_fw_evt success
    set_activation_status Staged
    wait_for_log_sync
    # stop the nv-sync.service to trigger the overlay sync and unmount before 'reboot -f'
    systemctl stop nv-sync.service
    # reboot
    reboot -f
}

pldm_update() {
    busctl call xyz.openbmc_project.pldm /xyz/openbmc_project/pldm/fwu \
        xyz.openbmc_project.PLDM.FWU.FWUBase StartFWUpdate s "$LOCAL_PATH"
    if [ $? -ne 0 ]; then
        log "initialising PLDM update failed"
        exit_fail
    fi
}

pmem_update() {
    busctl call xyz.openbmc_project.PMEM /xyz/openbmc_project/software \
        xyz.openbmc_project.Software.Update Update s "$LOCAL_PATH"
    if [ $? -ne 0 ]; then
        log "failed to start pmem update"
        exit_fail
    fi
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
                wget --no-check-certificate "$URI" -O "$LOCAL_PATH"
                if [ $? -ne 0 ]; then
                    log "wget $URI failed!"
                    return 1
                fi
                ;;
            file)
                LOCAL_PATH=$(echo $URI | sed 's,^file://,,')
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
    local magic=$(hexdump -n 4 -v -e '/1 "%02x"' "$LOCAL_PATH")
    case "$magic" in
        d00dfeed) ping_pong_update ;;
        19fdeab6) blk0blk1_update ;;
        edd5cb6d) smm_update ;;
        06000000) pmem_update ;;
        *)
            local magicPLDM=$(hexdump -n 16 -v -e '/1 "%02x"' "$LOCAL_PATH")
            if [[ $magicPLDM -eq f018878ccb7d49439800a02f059aca02 ]]; then
                log "PLDM magic matched "
                pldm_update
                return 0
            fi
            log "Unknown file type ${magic}"
            return 1
            ;;
    esac
}

# if this script was sourced, just return without executing anything
[ "$_" != "$0" ] && return 0 >&/dev/null

cleanup() {
    if [ $local_file -eq 0 ]; then
        rm -rf "$(dirname "$LOCAL_PATH")"
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
    if [[ "$1" == *"/"* ]]; then
        URI=$1 # local file
        local_file=1 ;
    else
        URI="file:///tmp/images/$1/image-runtime"
        img_obj=$1
        local_file=0 ;
    fi
fi
trap cleanup EXIT

fetch_fw && update_fw || exit_fail
