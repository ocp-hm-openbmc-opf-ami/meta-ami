#!/bin/sh
# Exit 0 when fwupd.sh marked a payload as requiring a BMC reboot.
set -eu

KEY="${1:-}"
MARKER_DIR="/run/fwupd-reboot-required"

if [ -z "$KEY" ]; then
	find "$MARKER_DIR" -mindepth 1 -maxdepth 1 -type f 2>/dev/null | grep -q . || exit 1
	exit 0
fi

MARKER_FILE="$MARKER_DIR/$(basename "$KEY")"
[ -f "$MARKER_FILE" ] || exit 1
exit 0
