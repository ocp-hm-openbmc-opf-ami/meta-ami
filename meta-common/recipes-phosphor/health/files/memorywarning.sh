#!/bin/sh

    echo "Clearing caches..."

    # Clear pagecache, dentries, and inodes
    sync && echo 3 | tee /proc/sys/vm/drop_caches

    # Clear systemd journal logs older than 1 day
    journalctl --vacuum-time=1d

    # Clear DNS cache (if using systemd-resolved)
    systemctl restart systemd-resolved

    # Clear slab cache
    echo 1 > /proc/sys/vm/drop_caches

    # Clear swap cache
    swapoff -a && swapon -a