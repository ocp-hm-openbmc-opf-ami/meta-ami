#!/bin/bash

# Sync the files/dirs specified in synclist once
# Usually the sync-manager could sync the file once before it starts, so that
# it makes sure the synclist is always synced when the sync-manager is running.

SYNCLIST=/etc/synclist
DEST_DIR=/run/media/rwfs-alt/.overlay/

if [ ! -d "$DEST_DIR" ]; then
    echo "Directory does not exist. Creating $DEST_DIR"
    mkdir -p "$DEST_DIR"
fi    
while read -r l; do
    echo rsync -a -R  "${l}" "${DEST_DIR}"
    rsync -a -R  "${l}" "${DEST_DIR}"
done < ${SYNCLIST}

