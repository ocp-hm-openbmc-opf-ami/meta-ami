#!/bin/sh
# /usr/libexec/fwupd/common.sh — runtime helpers for generated fwupd.sh
# NOTE: The generated fwupd.sh sets a global ERR trap; this file does not.

set -eu
# Global debug flag (set DEBUG=1 for verbose output)
DEBUG="${DEBUG:-0}"
###############################################################################
# Update percentages & statuses
###############################################################################
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

###############################################################################
# Core configuration
###############################################################################
: "${LOG_FILE:=/var/log/fwupd/fwupd.log}"
: "${LOCAL_FILE:=0}"  # default ON: perform D‑Bus operations

SW_SERVICE="xyz.openbmc_project.Software.BMC.Updater"
SW_BASE="/xyz/openbmc_project/software"
OMAP_SVC="xyz.openbmc_project.ObjectMapper"
OMAP_OBJ="/xyz/openbmc_project/object_mapper"
OMAP_IFACE="xyz.openbmc_project.ObjectMapper"
VER_IFACE="xyz.openbmc_project.Software.Version"

###############################################################################
# Basic logging utilities
###############################################################################

# Debug log function
debug_log() {
    [ "$DEBUG" = "1" ] && echo "[DEBUG] $*" >&2 || true
}
log() {
    echo "[INFO] $*" >&2
}
section()  { log "==== $* ===="; }

normalize_objid() { printf "%s" "$1" | sed -e 's#.*/##' -e 's/[^A-Za-z0-9._-]/_/g' -e 's/^\.*//' -e 's/\.*$//'; }
set_img_obj()     { IMG_OBJ="$(normalize_objid "$1")"; export IMG_OBJ; log "Software object: $SW_BASE/$IMG_OBJ"; }

###############################################################################
# D‑Bus helpers
###############################################################################
_has_cmd()      { command -v "$1" >/dev/null 2>&1; }
_has_busctl()   { _has_cmd busctl; }
ensure_dbus()   { _has_busctl || { echo "ERROR: busctl not present (D‑Bus required)"; exit 3; }; }
_use_dbus()     { lf="${LOCAL_FILE:-0}"; [ "$lf" -eq 0 ] && _has_busctl; }

dbus_set_prop() { busctl set-property "$1" "$2" "$3" "$4" "$5" "$6" 2>/dev/null || true; }
dbus_get_prop() { busctl get-property "$1" "$2" "$3" "$4" 2>/dev/null    || true; }

run_shell(){ log "SHELL: $1"; sh -c "$1"; }
run_script(){ p="$1"; shift || true; log "SCRIPT: $p $*"; "$p" "$@"; }
run_tool(){   p="$1"; shift || true; log "TOOL:   $p $*"; "$p" "$@"; }
run_dbus(){
  d="$1"; o="$2"; i="$3"; m="$4"; s="${5:-}"; shift 5 || true
  if [ -n "$s" ]; then
    log "DBUS: busctl call $d $o $i $m $s $*"
    busctl call "$d" "$o" "$i" "$m" "$s" "$@" || true
  else
    log "DBUS: busctl call $d $o $i $m"
    busctl call "$d" "$o" "$i" "$m" || true
  fi
}

###############################################################################
# Progress / Task status
###############################################################################
_current_img_obj() { [ -n "${IMG_OBJ:-}" ] && printf "%s" "$IMG_OBJ" || printf "%s" "${img_obj:-}"; }

set_progress() {
  val="${1:-0}"
  obj="$(_current_img_obj)"
  [ -n "$obj" ] || { log "set_progress($val): SKIP (no image object)"; return 0; }
  _use_dbus || { log "set_progress($val): SKIP (no D-Bus)"; return 0; }
  log "set_progress($val): $SW_BASE/$obj"
  dbus_set_prop "$SW_SERVICE" "$SW_BASE/$obj" \
    xyz.openbmc_project.Software.ActivationProgress Progress y "$val"
}

set_task_status() {
  status="${1:-$UPDATE_STATUS_RUNNING}"
  obj="$(_current_img_obj)"
  [ -n "$obj" ] || { log "set_task_status($status): SKIP (no image object)"; return 0; }
  _use_dbus || { log "set_task_status($status): SKIP (no D-Bus)"; return 0; }
  log "set_task_status($status): $SW_BASE/$obj"
  dbus_set_prop "$SW_SERVICE" "$SW_BASE/$obj" \
    xyz.openbmc_project.Common.Task Status s "xyz.openbmc_project.Common.Task.OperationStatus.${status}"
}

###############################################################################
# Redfish / journald logging
###############################################################################
# Percent & status mappers
update_percentage(){ local pct="${1:-}"; case "$pct" in (*[!0-9]*) return 0;; esac; set_progress "$pct" || true; }
update_status(){ local s="${1:-}"; case "$s" in \
  *EXCEPTION*|Exception) set_task_status "$UPDATE_STATUS_EXCEPTION";; \
  *RUNNING*|Running)     set_task_status "$UPDATE_STATUS_RUNNING";;  \
  *SUCCESS*|Completed|Success) set_task_status "$UPDATE_STATUS_COMPLETED";; \
  *) [ -n "$s" ] && set_task_status "$s" || true;; esac; }

# Optional hook (no-op unless overridden elsewhere)
create_Phosphor_log(){ :; }

_has_logger_systemd(){ command -v logger-systemd >/dev/null 2>&1; }
_has_logger(){ command -v logger >/dev/null 2>&1; }

_emit_redfish_journal(){
  # $1=message  $2=severity  $3=id  $4=args
  local _m="$1" _sev="$2" _id="$3" _args="$4"
  if _has_logger_systemd; then
    logger-systemd --journald <<-EOF
MESSAGE=${_m}
PRIORITY=2
SEVERITY=${_sev}
REDFISH_MESSAGE_ID=${_id}
REDFISH_MESSAGE_ARGS=${_args}
EOF
  elif _has_logger; then
    logger -t redfish "ID=${_id} SEV=${_sev} MSG=${_m} ARGS=${_args}"
  else
    log "REDFISH id=${_id} sev=${_sev} args=${_args} :: ${_m}"
  fi
}

redfish_log_fw_evt() {
    evt="$1"; sev=""; msg=""; evt_id=""
    [ -n "${FWTYPE:-}" ] || return 0
    [ -n "${FWVER:-}" ]  || return 0
    case "$evt" in
        start)
            update_percentage "$UPDATE_PERCENT_PRESTAGE_VERIFY_COMPLETE"
            evt_id="OpenBMC.0.4.0.FirmwareUpdateStarted"
            msg="$FWTYPE firmware update to version $FWVER started."
            sev="Informational"
            ;;
        success)
            update_percentage "$UPDATE_PERCENT_SUCCESS"
            evt_id="OpenBMC.0.4.0.FirmwareUpdateCompleted"
            msg="$FWTYPE firmware update to version $FWVER completed successfully."
            sev="Informational"
            ;;
        staged)
            update_percentage "$UPDATE_PERCENT_FLASH_OR_STAGE_START"
            evt_id="OpenBMC.0.4.0.FirmwareUpdateStaged"
            msg="$FWTYPE firmware update to version $FWVER staged successfully."
            sev="Informational"
            ;;
        *) return 0 ;;
    esac
    create_Phosphor_log || true
    _emit_redfish_journal "$msg" "$sev" "$evt_id" "${FWTYPE},${FWVER}"
}

redfish_log_abort() {
    local reason="${1:-Unknown error}"
    [ -n "${FWTYPE:-}" ] || return 0
    [ -n "${FWVER:-}" ]  || return 0
    local evt_id="OpenBMC.0.1.FirmwareUpdateFailed"
    local msg="$FWTYPE firmware update to version $FWVER failed: ${reason}."
    local sev="Warning"
    update_status "$UPDATE_STATUS_EXCEPTION"
    create_Phosphor_log || true
    _emit_redfish_journal "$msg" "$sev" "$evt_id" "${FWTYPE},${FWVER},${reason}"
}

###############################################################################
# Filesystem/log sync (as requested, best-effort on overlay path)
###############################################################################
wait_for_log_sync() {
    sync
    sync /tmp/.rwfs/.overlay 2>/dev/null || true
    sleep 5
}

###############################################################################
# OS / Platform helpers (shared across prepare/flash/cleanup scripts)
###############################################################################
# Best-effort stop (no discovery/state checks — idempotent and cheap)
_stop_if_active() {
  if command -v systemctl >/dev/null 2>&1; then
    systemctl is-active --quiet "$1" && systemctl stop "$1"  || true
  fi
}
# Stop, disable service if active
_disable_if_active() {
  if command -v systemctl >/dev/null 2>&1; then
    systemctl is-active --quiet "$1" && {
      systemctl stop "$1" || true
      systemctl disable "$1" || true
    }
  fi
}
_mask_service() {
  if command -v systemctl >/dev/null 2>&1; then
      systemctl mask "$1" || true
  fi
}

_unmask_service() {
  if command -v systemctl >/dev/null 2>&1; then
      systemctl unmask "$1" || true
  fi
}

# Start service if not active
_start_if_inactive() {
  if command -v systemctl >/dev/null 2>&1; then
    # Check if masked
    if systemctl is-enabled --quiet "$1" 2>/dev/null && systemctl is-active --quiet "$1"; then
      return 0
    fi
    if systemctl is-enabled --quiet "$1" 2>&1 | grep -q masked; then
      log "Service $1 is masked, unmasking before start."
      systemctl unmask "$1" || true
    fi
    systemctl is-active --quiet "$1" || systemctl start "$1" || true
  fi
}

# Is mountpoint mounted?
_is_mounted() {
  mp="$1"
  [ -n "$mp" ] || return 1
  awk -v m="$mp" '$2==m {found=1} END{exit (found?0:1)}' /proc/mounts 2>/dev/null
}

_is_mounted_safe() {
  if command -v _is_mounted >/dev/null 2>&1; then
    _is_mounted "$1"
  else
    mountpoint -q -- "$1" 2>/dev/null || grep -q " $(printf %s "$1" | sed 's/[\\.*^$[]/\\&/g') " /proc/mounts 2>/dev/null
  fi
}

# Unmount MTD/UBI-backed mount points (best-effort)
_unmount_mtds() {
  log "Unmounting MTD/UBI-backed mount points (best-effort)"
  while IFS=' ' read -r dev mp fstype _; do
    case "$dev:$fstype" in
      /dev/mtdblock*:*|/dev/ubi*:*|ubi*:*|/dev/ubiblock*:*|mtd:rwfs:*)
        if _is_mounted "$mp"; then
          log "Unmounting $mp (dev=$dev type=$fstype)"
          umount "$mp" >/dev/null 2>&1 || true
        fi
        ;;
    esac
  done < /proc/mounts
}

# Lookup mtd by label; returns mtdN (e.g., mtd3)
get_mtd_by_label() {
  lbl="$1"
  # Prefer sysfs (fast, no external tools)
  for namefile in /sys/class/mtd/mtd*/name; do
    [ -e "$namefile" ] || continue
    IFS= read -r name <"$namefile" || true
    [ "$name" = "$lbl" ] || continue
    printf '%s\n' "$(basename "$(dirname "$namefile")")"
    return 0
  done
  # Fallback to /proc/mtd parsing
  awk -F: -v l="$lbl" '
    /^mtd[0-9]+:/ { g=$1; sub(":","",g); if ($0 ~ "\"" l "\"") { print g; exit 0 } }
    END { exit 1 }
  ' /proc/mtd 2>/dev/null || true
}

###############################################################################
# Manifest purpose + target resolution
###############################################################################
detect_manifest_purpose(){
  dir="${1:-.}"
  if [ -f "$dir/MANIFEST" ]; then
    awk -F'=' '/^purpose=/{print $2}' "$dir/MANIFEST" \
      | sed -e 's/.*VersionPurpose\.//' -e 's/[^A-Za-z].*$//' \
      | tr '[:lower:]' '[:upper:]'
    return 0
  fi
  if [ -f "$dir/manifest.json" ]; then
    awk -F'"' '/[Pp]urpose/ {print $4}' "$dir/manifest.json" \
      | sed -e 's/.*VersionPurpose\.//' -e 's/[^A-Za-z].*$//' \
      | tr '[:lower:]' '[:upper:]'
    return 0
  fi
  printf '%s' ''
}

# ---------------- ObjectMapper helpers ----------------
mapper_get_service() {
  local obj="$1" iface="$2"
  local out
  if ! out="$(busctl call xyz.openbmc_project.ObjectMapper \
                 /xyz/openbmc_project/object_mapper \
                 xyz.openbmc_project.ObjectMapper GetObject \
                 sas "$obj" 1 "$iface" 2>/dev/null)"; then
    log "WARN: mapper lookup failed for obj=$obj iface=$iface"
    return 1
  fi
  awk -F'"' '
    BEGIN{wk=""; un=""}
    {for(i=2;i<=NF;i+=2){ s=$i; if (s ~ /^:/) { if (un=="") un=s; } else {wk=s; print wk; exit}}}
    END{if(wk=="") print un}
  ' <<<"$out"
}

dbus_get_property_by_mapper() {
  local obj="$1" iface="$2" prop="$3"
  local svc
  if ! svc="$(mapper_get_service "$obj" "$iface")"; then
    return 1
  fi
  busctl get-property "$svc" "$obj" "$iface" "$prop"
}

# Returns space-delimited basenames from HttpPushUriTargets on /xyz/openbmc_project/software
get_pushuri_targets() {
  # Use the well-known Updater service directly (no ObjectMapper here)
  local svc="xyz.openbmc_project.Software.BMC.Updater"
  local obj="/xyz/openbmc_project/software"
  local iface="xyz.openbmc_project.Software.FirmwareUpdateTarget"

  local raw
  raw="$(
    busctl get-property "$svc" "$obj" "$iface" HttpPushUriTargets 2>/dev/null \
      | awk -F'"' '{for(i=2;i<=NF;i+=2) print $i}' \
      | xargs -n1 basename 2>/dev/null \
      | sort -u | tr '\n' ' ' | awk '{$1=$1;print}'
  )"

  log "Push-URI targets (raw): ${raw:-<none>}"
  printf "%s\n" "${raw}"
}

# Keep only targets whose Version.Purpose equals the manifest PURPOSE
# Keep only targets whose Version.Purpose equals the manifest PURPOSE
filter_targets_by_manifest_purpose() {
  # usage: filter_targets_by_manifest_purpose "t1 t2 ..."
  local in="$1"
  local want="${PURPOSE:-}"
  local iface="xyz.openbmc_project.Software.Version"
  local prop="Purpose"
  local out="" t obj svc match val=""

  [ -n "$want" ] || {
    log "WARN: PURPOSE is empty; skipping validation"
    printf "%s\n" "$in"
    return 0
  }

  for t in $in; do
    obj="/xyz/openbmc_project/software/$t"
    if ! svc="$(mapper_get_service "$obj" "$iface")"; then
      [ "${FWUPD_DEBUG:-0}" != "0" ] && log "DEBUG: skip target=$t (no service for $iface)"
      continue
    fi

    # Extract Version.Purpose, e.g. "...VersionPurpose.BMC" -> "BMC"
    val="$(
      busctl get-property "$svc" "$obj" "$iface" "$prop" 2>/dev/null |
      awk -F'"' 'NR==1{for(i=2;i<=NF;i+=2){print $i;break}}' |
      sed -e 's/.*VersionPurpose\.//' -e 's/[^A-Za-z].*$//' |
      tr '[:lower:]' '[:upper:]' || :
    )"

    match="no"
    if [ -n "${val-}" ] && [ "$val" = "$want" ]; then
      out="$out $t"
      match="yes"
    fi

    [ "${FWUPD_DEBUG:-0}" != "0" ] && \
      log "DEBUG: target=$t version.purpose=${val:-<none>} want=$want match=$match"
  done

  # Trim leading space from $out
  out="$(printf "%s" "$out" | awk '{$1=$1;print}')"
  log "Valid targets (Purpose=${want}): ${out:-<none>}"
  printf "%s\n" "$out"
}

# Clear Push-URI targets and busy status
clear_pushuri_target_and_busy_status() {
  local svc="xyz.openbmc_project.Software.BMC.Updater"
  local obj="/xyz/openbmc_project/software"
  local iface="xyz.openbmc_project.Software.FirmwareUpdateTarget"

  log "Clearing Push-URI targets and busy status"
  
  busctl set-property "$svc" "$obj" "$iface" HttpPushUriTargets as 0 2>/dev/null || true
  busctl set-property "$svc" "$obj" "$iface" HttpPushUriTargetsBusy b false 2>/dev/null || true
}

###############################################################################
# FWUPD shared environment helpers (POSIX-safe)
###############################################################################

: "${FWENV_FILE:=/run/fwupd.env}"

# Return 0 if $1 is a valid shell var name: ^[A-Za-z_][A-Za-z0-9_]*$
_fw_valid_varname() {
  _name=$1
  [ -n "$_name" ] || return 1
  # First char must be letter or underscore
  case "$_name" in
    [!A-Za-z_]* ) return 1 ;;
  esac
  # All chars must be alnum or underscore
  case "$_name" in
    *[!A-Za-z0-9_]* ) return 1 ;;
  esac
  return 0
}

fwenv_load() {
  _fwenv_file="${ENV_FILE:-${FWENV_FILE}}"
  [ -r "$_fwenv_file" ] || return 0

  case $- in *e*) _fw_had_e=1 ;; *) _fw_had_e=0 ;; esac
  set +e
  set -a
  # shellcheck disable=SC1090
  . "$_fwenv_file"
  _fw_rc=$?
  set +a
  [ "$_fw_had_e" -eq 1 ] && set -e
  return $_fw_rc
}

fwenv_persist() {
  _fwenv_file="${ENV_FILE:-${FWENV_FILE}}"
  _fwenv_dir="$(dirname -- "$_fwenv_file")"
  [ -n "$_fwenv_dir" ] && mkdir -p -- "$_fwenv_dir" 2>/dev/null || true

  # Build a sed filter to drop old defs of keys we’re updating
  _fw_sed=
  for _fw_k in "$@"; do
    if ! _fw_valid_varname "$_fw_k"; then
      echo "fwenv_persist: skip invalid var name '$_fw_k'" >&2
      continue
    fi
    _fw_sed="$_fw_sed -e /^${_fw_k}=.*/d"
  done

  umask 077
  _fw_tmp="${_fwenv_file}.tmp.$$"
  : >"${_fw_tmp}" || { echo "fwenv_persist: cannot write ${_fw_tmp}" >&2; return 1; }

  # Keep existing keys except the ones we’re replacing
  if [ -f "$_fwenv_file" ] && [ -s "$_fwenv_file" ]; then
    # shellcheck disable=SC2086
    sed $_fw_sed "$_fwenv_file" > "${_fw_tmp}" 2>/dev/null || true
  fi

  # Append fresh KEY=VALUE lines
  for _fw_k in "$@"; do
    _fw_valid_varname "$_fw_k" || continue
    # Safely fetch the value; if unset with 'set -u', use empty
    _fw_v=$(eval "printf %s \"\${$_fw_k-}\"")
    # Reject values containing newline (keeps file systemd-friendly)
    case "$_fw_v" in *'
'*)
      echo "fwenv_persist: value of $_fw_k contains newline; skipped" >&2
      continue
      ;;
    esac
    printf '%s=%s\n' "$_fw_k" "$_fw_v" >> "${_fw_tmp}"
  done

  mv -f -- "${_fw_tmp}" "${_fwenv_file}"
}

fwenv_clear() {
  _fwenv_file="${ENV_FILE:-${FWENV_FILE}}"
  if [ "$#" -eq 0 ]; then
    rm -f -- "$_fwenv_file" 2>/dev/null || true
    return 0
  fi
  [ -f "$_fwenv_file" ] || return 0

  _fw_sed=
  for _fw_k in "$@"; do
    _fw_valid_varname "$_fw_k" || continue
    _fw_sed="$_fw_sed -e /^${_fw_k}=.*/d"
  done
  _fw_tmp="${_fwenv_file}.tmp.$$"
  # shellcheck disable=SC2086
  sed $_fw_sed "$_fwenv_file" > "${_fw_tmp}" 2>/dev/null || { rm -f -- "${_fw_tmp}"; return 0; }
  mv -f -- "${_fw_tmp}" "${_fwenv_file}"
}

# Auto-load on sourcing (opt-out with FWENV_AUTOLOAD=0)
if [ "${FWENV_AUTOLOAD:-1}" = "1" ]; then
  fwenv_load || true
fi

###############################################################################
# Multi-Firmware Update Rules
###############################################################################

# Constants for firmware update types
BMC_FW_UPDATING=1
OTHER_FW_UPDATING=2
RET_FAILED=1
RET_NORMAL=0

# Check if a given object ID represents a BMC firmware update
# Args: $1 - object ID or object path (e.g., "abc123def456" or "/xyz/openbmc_project/software/abc123def456")
# Returns: 0 if not BMC, 1 if BMC firmware
is_bmc_fw_update() {
    local obj_id
    obj_id="$(basename "$1")"
    local purpose_prop purpose_val
    
    [ -z "$obj_id" ] && return 0
    
    purpose_prop=$(dbus_get_prop "$SW_SERVICE" \
        "$SW_BASE/$obj_id" \
        "$VER_IFACE" \
        Purpose 2>/dev/null) || return 0
    
    purpose_val=$(printf "%s" "$purpose_prop" | awk '{print $2}' | tr -d '"')
    
    if [ "$purpose_val" = "xyz.openbmc_project.Software.Version.VersionPurpose.BMC" ]; then
        return 1  # IS BMC firmware
    fi
    return 0  # NOT BMC firmware
}

# Check if other firmware is currently being updated
# Args: $1 - current object ID to exclude from check
# Returns: 0 (none), BMC_FW_UPDATING (1), or OTHER_FW_UPDATING (2)
check_other_fw_updating() {
    local current_obj_id="$1"
    local obj_paths obj_id progress_prop progress_val purpose_prop purpose_val
    
    # Get all software objects
    obj_paths=$(busctl tree "$SW_SERVICE" 2>/dev/null | \
                grep -oE '/xyz/openbmc_project/software/[0-9a-f_]+' || true)
    
    [ -z "$obj_paths" ] && return 0
    
    printf "%s\n" "$obj_paths" | while IFS= read -r obj_path; do
        obj_id=$(basename "$obj_path")
        
        # Skip if:
        # - Object ID too short (< 16 chars)
        # - Same as current object being processed
        [ ${#obj_id} -le 15 ] && continue
        [ "$obj_id" = "$current_obj_id" ] && continue
        
        # Check activation progress
        progress_prop=$(dbus_get_prop "$SW_SERVICE" \
            "$obj_path" \
            "xyz.openbmc_project.Software.ActivationProgress" \
            Progress 2>/dev/null) || continue
        
        progress_val=$(printf "%s" "$progress_prop" | awk '{print $2}')
        
        # Skip completed or not-started updates (progress = 100 or empty)
        [ "$progress_val" = "100" ] && continue
        [ -z "$progress_val" ] && continue
        
        # Active update found - determine if it's BMC or other
        purpose_prop=$(dbus_get_prop "$SW_SERVICE" \
            "$obj_path" \
            "$VER_IFACE" \
            Purpose 2>/dev/null) || continue
        
        purpose_val=$(printf "%s" "$purpose_prop" | awk '{print $2}' | tr -d '"')
        
        if [ "$purpose_val" = "xyz.openbmc_project.Software.Version.VersionPurpose.BMC" ]; then
            return "$BMC_FW_UPDATING"
        else
            return "$OTHER_FW_UPDATING"
        fi
    done
}

# Verify if the current firmware update meets multi-firmware update rules
# Args: $1 - object ID of firmware being updated
# Returns: RET_NORMAL (0) if allowed, RET_FAILED (1) if blocked
#
# Rules:
# 1. If BMC firmware is updating → block all other updates
# 2. If other firmware is updating AND new request is BMC → block
# 3. Otherwise → allow
verify_multifirmware_rules() {
    local obj_id="$(basename "$1")"
    local other_fw_status
    
    [ -z "$obj_id" ] && {
        log "ERROR: verify_multifirmware_rules called without object ID"
        return "$RET_FAILED"
    }
    
    # Check if another firmware is currently being updated
    check_other_fw_updating "$obj_id"
    other_fw_status=$?
    
    case "$other_fw_status" in
        "$BMC_FW_UPDATING")
            # Rule 1: BMC update in progress → block all
            log "BLOCKED: BMC firmware update already in progress"
            return "$RET_FAILED"
            ;;
        "$OTHER_FW_UPDATING")
            # Rule 2: Other FW updating → check if current is BMC
            if is_bmc_fw_update "$obj_id"; then
                log "BLOCKED: Cannot update BMC while other firmware is updating"
                return "$RET_FAILED"
            fi
            # Non-BMC update while other non-BMC updating → allow
            log "ALLOWED: Non-BMC update while other firmware updating"
            return "$RET_NORMAL"
            ;;
        *)
            # No other updates in progress → allow
            log "ALLOWED: No conflicting firmware updates in progress"
            return "$RET_NORMAL"
            ;;
    esac
}


###############################################################################
###############################################################################
# Init
###############################################################################
ensure_dbus
