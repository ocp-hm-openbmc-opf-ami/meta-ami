#!/bin/sh
# flash-pldm.sh — PLDM FW update helper (aligned with flash-bmc-intel.sh/common.sh style)
# Usage: flash-pldm.sh IMAGE_DIR IMAGE_FD [TARGETS...]
#
# Notes:
#  * IMAGE_FD must be the numeric file descriptor number inherited from fwupd.sh
#    (exported as IMAGE_FD env var) pointing to the PLDM firmware bundle.
#  * Waits for a new Software object under /xyz/openbmc_project/software that
#    includes xyz.openbmc_project.Software.Activation, then monitors
#    Activation/ActivationProgress to completion.
#
set -eu
. /usr/libexec/fwupd/common.sh

# ---- journal logging override -----------------------------------------------
# Unlike the other flash scripts (which fwupd.sh runs serially in its main
# process, so their stderr reaches the journal), the pldm component is dispatched
# by fwupd.sh inside a backgrounded *parallel* subshell:
#     ( _fwupd_dispatch_with_image pldm ... ) &
# In that context this script's stderr is NOT delivered to the journal by the
# phosphor-software-manager launcher, so plain `echo >&2` logs are silently lost
# (verified empirically: logger-routed lines appear, stderr-only lines do not,
# while the parent fwupd.sh's own stderr keeps working).
#
# Override log()/debug_log() locally so that, when not attached to a terminal
# (i.e. running under the updater), we emit via logger(1) under the same "fwupd"
# identifier. Because this script's stderr is not separately captured, logger
# yields exactly ONE copy in `journalctl -t fwupd` with no duplication. When run
# interactively (stderr is a tty) we keep the normal stderr echo. This override
# is intentionally local to flash-pldm.sh; common.sh stays stderr-only so the
# serially-dispatched scripts are unaffected and never double-logged.
if command -v logger >/dev/null 2>&1; then
  log() {
    if [ -t 2 ]; then
      echo "[INFO] $*" >&2
    else
      logger -t "${FWUPD_LOG_TAG:-fwupd}" -p user.info -- "[INFO] $*" 2>/dev/null || echo "[INFO] $*" >&2
    fi
  }
  # debug_log is gated on debug being active (DEBUG=1 or /tmp/fwdebug present).
  # It is routed through logger so it survives the parallel-subshell stderr loss
  # (see log() above). It is emitted at user.info -- NOT user.debug -- because
  # journald's default level filters out user.debug, which would make enabling
  # /tmp/fwdebug appear to do nothing. Gating keeps it silent in production.
  debug_log() {
    _fwupd_debug_active || return 0
    if [ -t 2 ]; then
      echo "[DEBUG] $*" >&2
    else
      logger -t "${FWUPD_LOG_TAG:-fwupd}" -p user.info -- "[DEBUG] $*" 2>/dev/null || echo "[DEBUG] $*" >&2
    fi
  }
fi

IMAGE_DIR="${1:-}"
IMAGE_PATH="${2:-}"
shift 2 || true
TARGETS="$*"   # (not used by PLDM flow; kept for parity with fwupd.sh)

# Basic arg checks
if [ -z "$IMAGE_DIR" ] || [ -z "$IMAGE_PATH" ]; then
  echo "Usage: $0 IMAGE_DIR IMAGE_FD [TARGETS...]" >&2
  exit 2
fi

# Validate arg 2 is an open numeric fd (@IMAGEFD@ from fwupd.sh).
if ! echo "$IMAGE_PATH" | grep -Eq '^[0-9]+$' || ! [ -r "/proc/self/fd/$IMAGE_PATH" ]; then
  log "ERROR: arg 2 is not an accessible fd: ${IMAGE_PATH}"
  exit 2
fi
# Validate that IMAGE_FD env var (authoritative source used by _get_pldm_fd)
# matches the fd passed as arg 2; fail fast rather than discovering a mismatch
# inside the update sequence.
if [ "${IMAGE_FD:-}" != "$IMAGE_PATH" ]; then
  log "ERROR: IMAGE_FD env var (${IMAGE_FD:-<unset>}) does not match arg 2 ($IMAGE_PATH)"
  exit 2
fi
LOCAL_PATH="/proc/self/fd/$IMAGE_PATH"
debug_log "LOCAL_PATH resolved via fd: $LOCAL_PATH"

# ---- fail-safe trap ----------------------------------------------------------
_MONITOR_FIFO=""
_MONITOR_PID=""
trap '
  rc=$?
  [ -z "$_MONITOR_PID" ]  || kill "$_MONITOR_PID"  2>/dev/null || true
  [ -z "$_MONITOR_FIFO" ] || rm -f "$_MONITOR_FIFO"
  if [ $rc -ne 0 ]; then
    log "ERROR: PLDM update aborted (rc=$rc)"
    redfish_log_abort "PLDM update aborted"
    update_percentage "$UPDATE_PERCENT_FAIL"
  fi
  wait_for_log_sync
  exit $rc
' ERR INT HUP

# ---- helpers -----------------------------------------------------------------
ensure_prereqs() {
  debug_log "ensure_prereqs: checking for busctl"
  command -v busctl >/dev/null 2>&1 || {
    log "ERROR: busctl not found"
    redfish_log_abort "busctl missing"
    update_percentage "$UPDATE_PERCENT_FAIL"
    exit 127
  }
  # dbus-monitor is only useful here if we can ALSO line-buffer it with stdbuf:
  # dbus-monitor's stdout is stdio block-buffered when writing to a pipe/FIFO, so
  # without stdbuf its PropertiesChanged lines (progress AND the final Active) sit
  # in its buffer and never reach us -- giving no progress updates and forcing us
  # to rely entirely on the safety poll. The polling fallback, by contrast, reads
  # BOTH Progress and Activation via bounded busctl calls and needs neither
  # dbus-monitor nor stdbuf. So we only prefer the signal path when both
  # dbus-monitor and stdbuf are present; otherwise we poll.
  if command -v dbus-monitor >/dev/null 2>&1 && command -v stdbuf >/dev/null 2>&1; then
    HAVE_DBUS_MONITOR=1
  else
    HAVE_DBUS_MONITOR=0
    if ! command -v dbus-monitor >/dev/null 2>&1; then
      debug_log "ensure_prereqs: dbus-monitor not found; will use polling"
    else
      debug_log "ensure_prereqs: stdbuf not found; dbus-monitor would be block-buffered, will use polling"
    fi
  fi
  debug_log "ensure_prereqs: busctl OK ($(command -v busctl)) HAVE_DBUS_MONITOR=$HAVE_DBUS_MONITOR"
}

set_fw_meta_pldm() {
  local dir
  dir="${IMAGE_DIR%/}"
  FWTYPE="PLDM"
  FWVER=""
  debug_log "set_fw_meta_pldm: scanning $dir/MANIFEST"
  if [ -f "$dir/MANIFEST" ]; then
    FWVER="$(awk -F= '/^version=/ {print $2}' "$dir/MANIFEST" 2>/dev/null || true)"
    debug_log "set_fw_meta_pldm: MANIFEST version=$FWVER"
  else
    debug_log "set_fw_meta_pldm: no MANIFEST found, FWVER=NA"
  fi
  [ -n "$FWVER" ] || FWVER="NA"
  export FWTYPE FWVER
  debug_log "set_fw_meta_pldm: FWTYPE=$FWTYPE FWVER=$FWVER"
}

# Resolve the fd already prepared by fwupd.sh for @IMAGEFD@ dispatch.
_get_pldm_fd() {
  if echo "${IMAGE_FD:-}" | grep -Eq '^[0-9]+$' && [ -r "/proc/self/fd/$IMAGE_FD" ]; then
    printf '%s\n' "$IMAGE_FD"
    return 0
  fi

  log "Failed to access inherited image fd: ${IMAGE_FD:-<unset>}"
  return 1
}

# List the object paths that are DIRECT children of /xyz/openbmc_project/software
# and expose the Activation interface. We query pldmd directly via Introspect
# (busctl tree/introspect) rather than going through ObjectMapper or relying on
# the InterfacesAdded signal, because pldmd does not reliably emit InterfacesAdded
# for the activation object it creates during StartUpdate. Introspect always
# reflects the daemon's real, current object tree.
_list_pldm_activation_objects() {
  busctl tree xyz.openbmc_project.PLDM 2>/dev/null \
    | grep -oE '/xyz/openbmc_project/software/[A-Za-z0-9_./-]+' \
    | while IFS= read -r p; do
        # Only direct children of /software (e.g. /software/1782586474); skip the
        # update object itself and any deeper nested paths.
        case "${p#/xyz/openbmc_project/software/}" in */*) continue ;; esac
        [ "$p" = "/xyz/openbmc_project/software/pldm" ] && continue
        if busctl introspect xyz.openbmc_project.PLDM "$p" 2>/dev/null \
             | grep -q 'xyz\.openbmc_project\.Software\.Activation[[:space:]]'; then
          printf '%s\n' "$p"
        fi
      done
}

# List the firmware-inventory object paths exposed by pldmd. These are the direct
# children of /xyz/openbmc_project/software that implement
# xyz.openbmc_project.Software.Version (the per-component firmware inventory objects
# pldmd creates). Their basenames are exactly the component names that pldmd's
# StartUpdate matches the `targets` (ao) object paths against
# (UpdateManager::getComponentTargetList strips each target path to its basename and
# compares it to the component name). The update object itself (/software/pldm) and
# the transient activation objects (named with a numeric swId, which do NOT carry
# the Version interface) are excluded.
_list_pldm_software_inventory() {
  busctl tree xyz.openbmc_project.PLDM 2>/dev/null \
    | grep -oE '/xyz/openbmc_project/software/[A-Za-z0-9_./-]+' \
    | while IFS= read -r p; do
        # Only direct children of /software; skip the update object and deeper paths.
        case "${p#/xyz/openbmc_project/software/}" in */*) continue ;; esac
        [ "$p" = "/xyz/openbmc_project/software/pldm" ] && continue
        if busctl introspect xyz.openbmc_project.PLDM "$p" 2>/dev/null \
             | grep -q 'xyz\.openbmc_project\.Software\.Version[[:space:]]'; then
          printf '%s\n' "$p"
        fi
      done
}

# Build the `ao` (array-of-object-path) targets argument for StartUpdate by
# intersecting the requested TARGETS (space-separated basenames, e.g. "bmc_active")
# with pldmd's firmware inventory object paths, matched by basename. Echoes a busctl
# `ao` argument list of the form:  <count> <objpath1> <objpath2> ...
# If TARGETS is empty, or none of them match an inventory object, echoes "0" (an
# empty array, which makes pldmd update every applicable device).
_build_target_args() {
  local inv base n=0 paths="" t p
  [ -n "${TARGETS:-}" ] || { debug_log "targets: none requested -> empty array (0)"; printf '0\n'; return 0; }
  inv="$(_list_pldm_software_inventory)"
  if [ -z "$inv" ]; then
    debug_log "targets: pldmd exposes no firmware inventory -> empty array (0)"
    printf '0\n'
    return 0
  fi
  debug_log "targets: requested=[$TARGETS] inventory=[$(printf '%s' "$inv" | tr '\n' ' ')]"
  for t in $TARGETS; do
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      base="${p##*/}"
      if [ "$base" = "$t" ]; then
        paths="$paths $p"
        n=$((n+1))
        debug_log "targets: matched '$t' -> $p"
        break
      fi
    done <<EOF
$inv
EOF
  done
  if [ "$n" -eq 0 ]; then
    debug_log "targets: no requested target matched inventory -> empty array (0)"
    printf '0\n'
  else
    printf '%s%s\n' "$n" "$paths"
  fi
}

# Invoke Software.Update.StartUpdate on the PLDM update object using the inherited fd.
# pldmd implements StartUpdate to RETURN the freshly-created activation object path
# (sdbusplus::message::object_path). We capture and emit that path on stdout so the
# caller does not have to guess which /software/<swId> object is the current one —
# important because pldmd leaves prior activation objects in place after an update
# (they are not garbage-collected), so a plain "scan for an Activation object" could
# latch onto a stale object from a previous update.
#
# The final `ao` argument is the target list: the requested TARGETS intersected with
# pldmd's firmware inventory (see _build_target_args). When empty it is passed as the
# empty array `0`, which tells pldmd to update all applicable devices.
# Emits the returned object path on stdout; returns non-zero on failure.
_call_start_update() {
  local pldm_fd out rc target_args
  pldm_fd="$(_get_pldm_fd)" || return 1
  target_args="$(_build_target_args)"
  log "DBUS: busctl call xyz.openbmc_project.PLDM /xyz/openbmc_project/software/pldm xyz.openbmc_project.Software.Update StartUpdate hsbao $pldm_fd Immediate true $target_args"
  # shellcheck disable=SC2086 # $target_args is an intentional <count> path... word list
  out="$(busctl call xyz.openbmc_project.PLDM /xyz/openbmc_project/software/pldm \
    xyz.openbmc_project.Software.Update StartUpdate \
    "hsbao" "$pldm_fd" \
    "xyz.openbmc_project.Software.ApplyTime.RequestedApplyTimes.Immediate" \
    true $target_args 2>&1)"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    log "Failed to call StartUpdate method (rc=$rc): $out"
    return 1
  fi
  # Reply for a method returning object_path looks like: o "/xyz/openbmc_project/software/<swId>"
  printf '%s\n' "$out" \
    | grep -oE '/xyz/openbmc_project/software/[A-Za-z0-9_.-]+' \
    | head -n1
  return 0
}

# Call StartUpdate and resolve the activation object path for THIS update.
# Primary source: the object path returned by StartUpdate itself (authoritative,
# unambiguous even though stale objects from previous updates persist).
# Fallback: if the return value could not be parsed, snapshot the pre-existing
# activation objects, then poll for a NEW one to appear (set difference), so a
# leftover object from a previous update is never mistaken for the current one.
# $1 = max seconds to wait for the fallback (default 60).
_start_update_and_find_activation_object() {
  local maxwait="${1:-60}" waited=0 before_file now obj=""

  before_file="$(mktemp /tmp/pldm-actbefore-XXXXXX)"
  _list_pldm_activation_objects | sort -u > "$before_file"
  debug_log "find: pre-update activation objects: $(tr '\n' ' ' < "$before_file")"

  # Primary: use the object path returned by StartUpdate.
  obj="$(_call_start_update)" || { rm -f "$before_file"; return 1; }
  if printf '%s' "$obj" | grep -qE '^/xyz/openbmc_project/software/'; then
    debug_log "find: StartUpdate returned activation object: $obj"
    rm -f "$before_file"
    printf '%s\n' "$obj"
    return 0
  fi

  # Fallback: poll for a brand-new activation object (excluding pre-existing/stale).
  debug_log "find: StartUpdate did not return a usable path; falling back to polling"
  while [ "$waited" -lt "$maxwait" ]; do
    now="$(_list_pldm_activation_objects | sort -u)"
    obj="$(printf '%s\n' "$now" | grep -vxF -f "$before_file" | grep -E '^/xyz/openbmc_project/software/' | head -n1)"
    if [ -n "$obj" ]; then
      debug_log "find: new activation object detected after ${waited}s: $obj"
      rm -f "$before_file"
      printf '%s\n' "$obj"
      return 0
    fi
    sleep 1
    waited=$((waited+1))
  done

  rm -f "$before_file"
  debug_log "find: no new activation object appeared within ${maxwait}s"
  return 1
}

# Read the current Activation state once (best-effort). Echoes the bare state
# token (e.g. ...Activations.Active) or empty if unreadable.
#
# IMPORTANT: use PLAIN `busctl get-property` -- NOT `busctl --timeout=N`. The
# BMC's busctl accepts --timeout in --help but it does NOT work for get-property
# on this build: the call returns empty, so the monitor never observes the
# terminal Active state and hangs to maxwait. Plain get-property is proven to
# work on the BMC (it is what main() uses). sd-bus's default method timeout
# (~25s) bounds the call; pldmd queues it and answers once it is responsive
# again after the firmware transfer, so this stays busy-tolerant.
_read_activation_state() {
  busctl get-property xyz.openbmc_project.PLDM "$1" \
    xyz.openbmc_project.Software.Activation Activation 2>/dev/null \
    | awk '{print $NF}' | tr -d '"'
}

# Monitor the activation object to completion using dbus-monitor (PREFERRED).
#
# dbus-monitor passively receives the PropertiesChanged broadcast signals that
# pldmd emits for Activation/ActivationProgress. Because these are fire-and-forget
# broadcasts (no round-trip into pldmd), monitoring is NOT starved when pldmd is
# busy pumping the firmware transfer — unlike property polling, which must call
# into the daemon and times out under load.
#
# The object path is already known (returned by StartUpdate), so there is no
# discovery race: we register the match on this specific path, then do a single
# catch-up read in case the activation reached a terminal state in the brief
# window before the monitor was listening.
#
# $1 = object path, $2 = max seconds (default 1600).
#   return 0=Active 2=Failed 3=Invalid 5=timeout 9=setup error
_monitor_activation_via_signals() {
  local obj="$1" maxwait="${2:-1600}" line current_iface="" prog st
  local start_ts last_poll now_ts poll_interval=10 safety_poll_interval=60 match

  _MONITOR_FIFO="$(mktemp -u /tmp/pldm-mon-XXXXXX)"
  if ! mkfifo "$_MONITOR_FIFO" 2>/dev/null; then
    log "ERROR: could not create monitor FIFO $_MONITOR_FIFO"
    _MONITOR_FIFO=""
    return 9
  fi

  match="type='signal',path='$obj',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'"
  if command -v stdbuf >/dev/null 2>&1; then
    debug_log "monitor: starting line-buffered dbus-monitor (stdbuf)"
    timeout "${maxwait}s" stdbuf -oL dbus-monitor --system "$match" \
      > "$_MONITOR_FIFO" 2>/dev/null &
  else
    debug_log "monitor: starting (block-buffered) dbus-monitor"
    timeout "${maxwait}s" dbus-monitor --system "$match" \
      > "$_MONITOR_FIFO" 2>/dev/null &
  fi
  _MONITOR_PID=$!
  debug_log "monitor: dbus-monitor pid=$_MONITOR_PID match=[$match]"
  debug_log "monitor: dbus-monitor alive? $(kill -0 "$_MONITOR_PID" 2>/dev/null && echo yes || echo no)"

  # Catch-up: handle the case where pldmd already moved to a terminal state
  # between StartUpdate returning and the monitor attaching.
  st="$(_read_activation_state "$obj")"
  case "$st" in
    *Activations.Active)  log "PLDM Activation already Active";  _monitor_cleanup; return 0 ;;
    *Activations.Failed)  log "PLDM Activation failed";          _monitor_cleanup; return 2 ;;
    *Activations.Invalid) log "PLDM Activation invalid";         _monitor_cleanup; return 3 ;;
  esac

  # Consume the signal stream with a periodic safety poll. Interface context is
  # tracked so variant lines are interpreted under the interface they belong to
  # (Progress vs Activation). `read -t poll_interval` wakes the loop even when no
  # signal arrives so we can re-check the overall timeout; signals (progress and
  # the terminal Activation) are still read the instant they arrive. The safety
  # poll -- the ONLY thing that issues a D-Bus call and thus adds bus traffic --
  # is rate-limited to safety_poll_interval (much larger than poll_interval) so it
  # does not overwhelm pldmd: it is a fallback for a missed/buffered signal, not
  # the primary completion detector. After the firmware transfer completes pldmd
  # is responsive again, so this read succeeds.
  start_ts="$(date +%s 2>/dev/null || echo 0)"
  last_poll="$start_ts"
  local read_rc lines_seen=0
  exec 3< "$_MONITOR_FIFO"
  debug_log "monitor: entering consume loop (poll_interval=${poll_interval}s safety_poll_interval=${safety_poll_interval}s maxwait=${maxwait}s)"
  while :; do
    now_ts="$(date +%s 2>/dev/null || echo 0)"
    if [ "$start_ts" -ne 0 ] && [ $((now_ts - start_ts)) -ge "$maxwait" ]; then
      break
    fi

    line=""
    read_rc=0
    IFS= read -t "$poll_interval" -r line <&3 || read_rc=$?
    if [ "$read_rc" -eq 0 ]; then
      lines_seen=$((lines_seen+1))
      case "$line" in
        *"interface=org.freedesktop.DBus.Properties"*)
          current_iface=""; continue ;;
      esac
      if [ -z "$current_iface" ]; then
        case "$line" in
          *'string "xyz.openbmc_project.Software.'*)
            current_iface="$(printf '%s' "$line" | sed 's/.*string "//;s/".*//')"
            debug_log "monitor: tracking interface=$current_iface"
            continue ;;
        esac
      fi
      case "$line" in
        *variant*)
          case "$current_iface" in
            *ActivationProgress)
              prog="$(printf '%s' "$line" | awk '{print $NF}')"
              case "$prog" in
                ''|*[!0-9]*) : ;;
                *) debug_log "monitor: progress=$prog%"; update_percentage "$prog" || true ;;
              esac
              ;;
            *.Activation)
              # NOTE: trailing wildcard is REQUIRED. The raw dbus-monitor line is
              #   variant   string "xyz...Activations.Active"
              # i.e. it ends with a double-quote, so `*Activations.Active)` (which
              # means "ENDS WITH Activations.Active") does NOT match. Use
              # `*Activations.Active*)` so the closing quote is tolerated.
              case "$line" in
                *Activations.Active*)
                  log "PLDM Activation completed successfully (signal)"; exec 3<&-; _monitor_cleanup; return 0 ;;
                *Activations.Failed*)
                  log "PLDM Activation failed (signal)";  exec 3<&-; _monitor_cleanup; return 2 ;;
                *Activations.Invalid*)
                  log "PLDM Activation invalid (signal)"; exec 3<&-; _monitor_cleanup; return 3 ;;
                *)
                  debug_log "monitor: Activation transient: $line" ;;
              esac
              ;;
          esac
          ;;
      esac
      continue
    fi

    # read returned non-zero: a poll_interval timeout (no signal) or dbus-monitor
    # exited/EOF. Distinguish via monitor liveness so a plain timeout is never
    # mistaken for EOF.
    if ! kill -0 "$_MONITOR_PID" 2>/dev/null; then
      debug_log "monitor: dbus-monitor process EXITED (read_rc=$read_rc, lines_seen=$lines_seen); switching to final check"
      exec 3<&-
      break
    fi
    debug_log "monitor: read timeout (read_rc=$read_rc, no signal in ${poll_interval}s, lines_seen=$lines_seen, elapsed=$((now_ts - start_ts))s)"

    # Periodic safety poll (plain busctl get-property; bounded by sd-bus default,
    # busy-tolerant). Catches the terminal state even when the dbus-monitor signal
    # line is buffered/missed. After the firmware transfer completes pldmd is
    # responsive again, so this read succeeds.
    now_ts="$(date +%s 2>/dev/null || echo 0)"
    if [ $((now_ts - last_poll)) -ge "$safety_poll_interval" ]; then
      last_poll="$now_ts"
      st="$(_read_activation_state "$obj")"
      debug_log "monitor: safety poll -> state=[${st:-<unreadable>}] elapsed=$((now_ts - start_ts))s"
      case "$st" in
        *Activations.Active)  log "PLDM Activation completed successfully (safety poll)"; exec 3<&-; _monitor_cleanup; return 0 ;;
        *Activations.Failed)  log "PLDM Activation failed (safety poll)";  exec 3<&-; _monitor_cleanup; return 2 ;;
        *Activations.Invalid) log "PLDM Activation invalid (safety poll)"; exec 3<&-; _monitor_cleanup; return 3 ;;
        *) : ;;
      esac
    fi
  done
  exec 3<&- 2>/dev/null || true

  # FIFO closed: dbus-monitor exited (timeout reached or killed) without a
  # terminal Activation signal. Do a final catch-up read before declaring timeout.
  st="$(_read_activation_state "$obj")"
  _monitor_cleanup
  case "$st" in
    *Activations.Active)  log "PLDM Activation completed successfully (final read)"; return 0 ;;
    *Activations.Failed)  log "PLDM Activation failed (final read)";  return 2 ;;
    *Activations.Invalid) log "PLDM Activation invalid (final read)"; return 3 ;;
  esac
  log "PLDM activation monitor ended without terminal state (timeout ${maxwait}s)"
  return 5
}

_monitor_cleanup() {
  [ -z "$_MONITOR_PID" ]  || kill "$_MONITOR_PID"  2>/dev/null || true
  [ -z "$_MONITOR_FIFO" ] || rm -f "$_MONITOR_FIFO"
  _MONITOR_PID=""
  _MONITOR_FIFO=""
}

# Poll the Activation/ActivationProgress properties of $1 until the activation
# reaches a terminal state. Pushes progress updates as they change.
# $2 = max seconds to wait (default 1600).
#   return 0=Active(success) 2=Failed 3=Invalid 5=timeout
#
# IMPORTANT: During the firmware data transfer pldmd is single-threaded and busy
# pumping MCTP traffic, so D-Bus calls to it frequently fail or time out — and
# this affects EVERY call, including `busctl tree` (the same congestion makes
# phosphor-image-updater log "Connection timed out"). Therefore we must NOT try
# to detect "object removed" by querying pldmd, because those queries are starved
# by the very same busyness and would falsely report the object as gone.
#
# pldmd does not delete the activation object during an in-progress update; a real
# failure is surfaced as the Activation property value Activations.Failed/Invalid
# (which we read once pldmd becomes responsive again). So an unreadable property
# is ALWAYS treated as transient "pldmd busy" and we simply keep polling until we
# read a terminal Activation state or hit the overall maxwait timeout.
_poll_activation_to_completion() {
  local obj="$1" maxwait="${2:-1600}" waited=0 act prog last="-1" unreadable=0
  debug_log "poll: monitoring activation on $obj (maxwait=${maxwait}s)"
  while [ "$waited" -lt "$maxwait" ]; do
    # Use PLAIN busctl get-property (NOT --timeout=N: that option is accepted by
    # the BMC's busctl --help but silently fails for get-property, returning
    # empty). sd-bus's default method timeout bounds the call; a busy pldmd just
    # queues it and answers when responsive.
    act="$(busctl get-property xyz.openbmc_project.PLDM "$obj" \
      xyz.openbmc_project.Software.Activation Activation 2>/dev/null \
      | awk '{print $NF}' | tr -d '"')"
    prog="$(busctl get-property xyz.openbmc_project.PLDM "$obj" \
      xyz.openbmc_project.Software.ActivationProgress Progress 2>/dev/null \
      | awk '{print $NF}')"

    case "$prog" in
      ''|*[!0-9]*) : ;;
      *) if [ "$prog" != "$last" ]; then
           debug_log "poll: progress=$prog%"
           update_percentage "$prog" || true
           last="$prog"
         fi ;;
    esac

    case "$act" in
      *Activations.Active)
        log "PLDM Activation completed successfully (progress=${prog:-?})"
        return 0 ;;
      *Activations.Failed)
        log "PLDM Activation failed"
        return 2 ;;
      *Activations.Invalid)
        log "PLDM Activation invalid"
        return 3 ;;
      '')
        # Unreadable == pldmd busy with the transfer. Keep waiting; do NOT query
        # the tree (it is starved too). Periodically note we are still alive.
        unreadable=$((unreadable+1))
        if [ $((unreadable % 10)) -eq 0 ]; then
          log "PLDM activation state not yet readable (pldmd busy); still waiting (${waited}s, last progress=${last}%)"
        else
          debug_log "poll: Activation unreadable (pldmd busy) — continuing (${waited}s)"
        fi
        ;;
      *)
        unreadable=0
        debug_log "poll: Activation=$act (transient)"
        ;;
    esac

    sleep 3
    waited=$((waited+3))
  done

  log "PLDM activation timed out after ${maxwait}s without reaching a terminal state"
  return 5
}

# ---- main -------------------------------------------------------------------
log "start pldm update"
section "PLDM UPDATE"
[ -r "${LOCAL_PATH}" ] || {
  log "ERROR: image not found: ${LOCAL_PATH}"
  redfish_log_abort "PLDM image not found"
  update_percentage "$UPDATE_PERCENT_FAIL"
  exit 2
}

log "IMAGE_DIR=${IMAGE_DIR} IMAGE_FD=${IMAGE_PATH} TARGETS=${TARGETS:-<none>}"
debug_log "main: LOCAL_PATH=$LOCAL_PATH DEBUG=${DEBUG:-0}"

set_fw_meta_pldm
ensure_prereqs
log "PLDM context: FWTYPE=${FWTYPE} FWVER=${FWVER} PID=$$ TARGETS=${TARGETS:-<none>}"

# Stage event to match original flow
redfish_log_fw_evt staged || true
update_percentage "$UPDATE_PERCENT_PRESTAGE_VERIFY_START"

log "Calling StartUpdate and polling for new Activation object (fd=${IMAGE_PATH})"
obj_path="$(_start_update_and_find_activation_object 60 || true)"
obj_path="$(printf '%s\n' "$obj_path" | awk '{for (i=1;i<=NF;i++) if ($i ~ /^\/xyz\/openbmc_project\/software\//) {print $i; exit}}')"
if [ -z "$obj_path" ]; then
  log "No new Activation object appeared after StartUpdate."
  redfish_log_abort "PLDM Update - Activation interface not found"
  update_percentage "$UPDATE_PERCENT_FAIL"
  exit 1
fi

log "Found object with Activation interface: $obj_path"

# Check current Activation state before polling — pldmd may have already set it
# to a terminal state (e.g. Failed on invalid package header, or Active if the
# update completed extremely quickly).
_cur_activation=$(busctl get-property xyz.openbmc_project.PLDM "$obj_path" \
  xyz.openbmc_project.Software.Activation Activation 2>/dev/null | awk '{print $NF}' | tr -d '"' || true)
log "Current Activation state: ${_cur_activation:-<unreadable>}"
case "$_cur_activation" in
  *Activations.Failed)
    log "ERROR: PLDM object already in Failed state — package rejected by pldmd"
    redfish_log_abort "PLDM Update - package rejected (Activation=Failed)"
    update_percentage "$UPDATE_PERCENT_FAIL"
    exit 1
    ;;
  *Activations.Active)
    log "PLDM object already Active — treating as success"
    update_percentage "$UPDATE_PERCENT_SUCCESS"
    exit 0
    ;;
esac

# Monitor the activation object to completion.
log "Monitoring activation progress on $obj_path"
# NOTE: capture the return code directly (do NOT use `if ! cmd; then rc=$?`,
# because $? inside that branch is the status of the negation, not of cmd).
# The `|| rc=$?` form both captures the code and prevents `set -e` from aborting
# on a non-zero (failure) return.
rc=0
if [ "${HAVE_DBUS_MONITOR:-0}" = "1" ]; then
  _monitor_activation_via_signals "$obj_path" 1600 || rc=$?
  # dbus-monitor setup failure (rc=9): fall back to polling rather than aborting.
  if [ "$rc" -eq 9 ]; then
    log "dbus-monitor unavailable at runtime; falling back to property polling"
    rc=0
    _poll_activation_to_completion "$obj_path" 1600 || rc=$?
  fi
else
  _poll_activation_to_completion "$obj_path" 1600 || rc=$?
fi
if [ "$rc" -ne 0 ]; then
  log "PLDM activation monitor returned failure (rc=$rc)"
  case "$rc" in
    2) redfish_log_abort "PLDM Update - Activation failed" ;;
    3) redfish_log_abort "PLDM Update - Activation invalid" ;;
    5) redfish_log_abort "PLDM Update - Activation timed out or object removed" ;;
    *) redfish_log_abort "PLDM Update - Unknown error" ;;
  esac
  update_percentage "$UPDATE_PERCENT_FAIL"
  exit 1
fi

# Done
debug_log "main: activation complete, logging success and setting 100%"
redfish_log_fw_evt success || true
update_percentage "$UPDATE_PERCENT_SUCCESS"
log "PLDM update stage complete."
exit 0