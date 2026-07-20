#!/bin/sh
fslist="proc sys dev run"
rodir=run/initramfs/ro
rwdir=run/initramfs/rw
upper=$rwdir/cow
work=$rwdir/work

cd /
# shellcheck disable=SC2086
mkdir -p $fslist
mount dev dev -t devtmpfs
mount sys sys -t sysfs
mount proc proc -t proc
if ! grep -w " run " /proc/mounts >/dev/null 2>&1; then
  mount -t tmpfs -o mode=755,nodev tmpfs run
fi

mkdir -p "$rodir" "$rwdir"
cp -rp init shutdown update whitelist bin sbin usr lib etc var run/initramfs

# To start an interactive shell with job control at this point, run
# getty 38400 ttyS4

findmtd() {
  m=$(grep -xl "$1" /sys/class/mtd/*/name 2>/dev/null || true)
  m=${m%/name}
  m=${m##*/}
  echo "$m"
}

# Emulate util-linux's `blkid -s TYPE -o value $1`
blkid_fs_type() {
  blkid "$1" 2>/dev/null | sed -e 's/^.*TYPE=\"//' -e 's/\".*$//'
}

probe_fs_type() {
  fst=$(blkid_fs_type "$1")
  echo "${fst:=jffs2}"
}

# Read U-Boot env var directly from MTD (CRC not checked; legacy behavior)
get_fw_env_var() {
  copies=2
  envdev=$(findmtd u-boot-env)
  if test -n "$envdev"; then
    tr '\n\000' '\r\n' < "/dev/$envdev" | \
      tail -c +5 | tail -c +$((copies-1)) | \
      sed -ne '/^$/,$d' -e "s/^$1=//p"
  fi
}

setup_resolv() {
  runresolv=/run/systemd/resolve/resolv.conf
  etcresolv=/etc/resolv.conf
  if test ! -e "$etcresolv" -a ! -L "$etcresolv"; then
    mkdir -p "${runresolv%/*}"
    ln -s "$runresolv" "$etcresolv"
  fi
  if test ! -f "$runresolv"; then
    cat /proc/net/pnp > "$runresolv" || true
  fi
  return 0
}

try_tftp() {
  rest="${1#tftp://}"
  path=${rest#*/}
  host=${rest%"$path"}
  host="${host%/}"
  port="${host#"${host%:*}"}"
  host="${host%"$port"}"
  port="${port#:}"
  setup_resolv
  if test -z "$host" -o -z "$path"; then
    debug_takeover "Invalid tftp download url '$url'."
  elif echo "Downloading '$url' from $host ..." && \
       ! tftp -g -r "$path" -l /run/image-rofs "$host" ${port+"$port"}; then
    debug_takeover "Download of '$url' failed."
  fi
}

try_wget() {
  setup_resolv
  echo "Downloading '$1' ..."
  if ! wget -O /run/image-rofs "$1"; then
    debug_takeover "Download of '$url' failed."
  fi
}

debug_takeover() {
  echo "$@"
  if ! grep -w enable-initrd-debug-sh "$optfile" >/dev/null 2>&1; then
    echo "Fatal error, triggering kernel panic!"
    exit 1
  fi
  test -n "$@" && echo "Try to manually fix."
  cat << HERE
After fixing run exit to continue this script, or reboot -f to retry, or
touch /takeover and exit to become PID 1 allowing editing of this script.
HERE
  while ! /bin/sh && ! test -f /takeover; do
    echo "/bin/sh failed, retrying"
  done
  # Touch /takeover in the above shell to become pid 1
  if test -e /takeover; then
    cat << HERE
Takeover of init requested. Executing /bin/sh as PID 1.
When finished exec new init or cleanup and run reboot -f.
Warning: No job control! Shell exit will panic the system!
HERE
    export PS1="init# "
    exec /bin/sh
  fi
}

# ---------- helpers for failure diagnostics ----------
dump_labels_and_blkid() {
  echo "[obmc-init] ===== Debug: labels & blkid dump begin ====="
  if [ -d /dev/disk/by-label ]; then
    echo "[obmc-init] /dev/disk/by-label:"
    ls -l /dev/disk/by-label 2>/dev/null || echo "[obmc-init]   (ls failed)"
  else
    echo "[obmc-init] /dev/disk/by-label: (not present yet)"
  fi
  echo "[obmc-init] blkid:"
  if command -v blkid >/dev/null 2>&1; then
    blkid 2>/dev/null || echo "[obmc-init]   (blkid returned non-zero)"
  else
    echo "[obmc-init] blkid: not available in initramfs"
  fi
  echo "[obmc-init] ===== Debug: labels & blkid dump end ====="
}

# ---------- Locate rofs on SPI (MTD) ----------
rofs=$(findmtd rofs)
rodev=/dev/mtdblock${rofs#mtd}
rofst=squashfs

# ---------- Prefer rwfs by filesystem LABEL (eMMC), then blkid, then MTD ----------
rw_mtd_name=""

choose_rwfs_blockdev() {
  # Try up to ~2s to tolerate slow uevents
  i=0
  while [ $i -lt 10 ]; do
    # 1) If udev provided by-label symlink, use it
    if [ -e /dev/disk/by-label/rwfs ]; then
      echo /dev/disk/by-label/rwfs
      return 0
    fi
    # 2) util-linux style: -t LABEL=... -o device
    dev="$(blkid -t LABEL=rwfs -o device 2>/dev/null | head -n1)"
    if [ -n "$dev" ]; then
      echo "$dev"
      return 0
    fi
    # 3) BusyBox-compatible: parse plain blkid output
    if command -v blkid >/dev/null 2>&1; then
      dev="$(blkid 2>/dev/null | sed -n 's#^\(/[^:]*\):.*LABEL="rwfs".*$#\1#p' | head -n1)"
      if [ -n "$dev" ]; then
        echo "$dev"
        return 0
      fi
    fi
    i=$((i+1))
    sleep 0.2
  done
  return 1
}

if rwdev="$(choose_rwfs_blockdev)"; then
  # Block device (eMMC) path
  rwfst="$(blkid_fs_type "$rwdev")"
  rwfst="${rwfst:-ext4}"
  force_rwfst_jffs2=n
else
  # Legacy fallback: rwfs on MTD
  rw_mtd_name="$(findmtd rwfs)"
  if [ -n "$rw_mtd_name" ]; then
    rwdev="/dev/mtdblock${rw_mtd_name#mtd}"
    rwfst="$(probe_fs_type "$rwdev")"
    force_rwfst_jffs2=y
  else
    # Final fallback: no persistent RWFS; run overlay in RAM for this boot
    rwdev="<none>"
    rwfst=none
    force_rwfst_jffs2=n
    echo "[obmc-init] ERROR: rwfs not found by LABEL nor on MTD; overlay will be in RAM"
    dump_labels_and_blkid
  fi
fi

# Common options
roopts=ro
rwopts=rw
image=/run/initramfs/image-
trigger=${image}rwfs
init=/sbin/init
fsckbase=/sbin/fsck.
fsck=$fsckbase$rwfst
fsckopts=-a
optfile=/run/initramfs/init-options
optbase=/run/initramfs/init-options-base
urlfile=/run/initramfs/init-download-url
update=/run/initramfs/update

# Bring in any runtime overrides for options
if test -e "/${optfile##*/}"; then
  cp "/${optfile##*/}" "$optfile"
fi
if test -e "/${optbase##*/}"; then
  cp "/${optbase##*/}" "$optbase"
else
  touch "$optbase"
fi
if test ! -f "$optfile"; then
  cat /proc/cmdline "$optbase" > "$optfile"
  get_fw_env_var openbmcinit >> "$optfile"
  get_fw_env_var openbmconce >> "$optfile"
fi

echo "[obmc-init] rofs: device=$rodev fstype=$rofst (SPI NOR)"
echo "[obmc-init] rwfs: device=$rwdev fstype=$rwfst (LABEL/blkid discovery)"

# Download hooks (unchanged)
consider_download_files=y
consider_download_tftp=y
consider_download_http=y
consider_download_ftp=y
flash_images_before_init=n

if grep -w debug-init-sh "$optfile" >/dev/null 2>&1; then
  if grep -w enable-initrd-debug-sh "$optfile" >/dev/null 2>&1; then
    debug_takeover "Debug initial shell requested by command line."
  else
    echo "Need to also add enable-initrd-debug-sh for debug shell."
  fi
fi
if test "$consider_download_files" = "y" && \
   grep -w openbmc-init-download-files "$optfile" >/dev/null 2>&1; then
  if test -f "${urlfile##*/}"; then
    cp "${urlfile##*/}" "$urlfile"
  fi
  if test ! -f "$urlfile"; then
    get_fw_env_var openbmcinitdownloadurl > "$urlfile"
  fi
  url="$(cat "$urlfile" 2>/dev/null)"
  rest="${url#*://}"
  proto="${url%"$rest"}"

  if test -z "$url"; then
    echo "Download url empty. Ignoring download request."
  elif test -z "$proto"; then
    echo "Download failed."
  elif test "$proto" = tftp://; then
    if test "$consider_download_tftp" = "y"; then
      try_tftp "$url"
    else
      echo "Download failed."
    fi
  elif test "$proto" = http://; then
    if test "$consider_download_http" = "y"; then
      try_wget "$url"
    else
      echo "Download failed."
    fi
  elif test "$proto" = ftp://; then
    if test "$consider_download_ftp" = "y"; then
      try_wget "$url"
    else
      echo "Download failed."
    fi
  else
    echo "Download failed."
  fi
fi

# If there are images in /, move them to /run/initramfs/ or /run
imagebasename=${image##*/}
if test -n "${imagebasename}" && ls "/${imagebasename}"* >/dev/null 2>&1; then
  if test "$flash_images_before_init" = "y"; then
    echo "Flash images found, will update before starting init."
    mv "/${imagebasename}"* "${image%"$imagebasename"}"
  else
    echo "Flash images found, will use but deferring flash update."
    mv "/${imagebasename}"* /run/
  fi
fi

# Helper to clear RWFS depending on media type
clear_rwfs() {
  echo "Clearing read-write overlay filesystem."
  if echo "$rwdev" | grep -q mtdblock; then
    # MTD: use flash_eraseall on the MTD partition name (not the block node)
    test -n "$rw_mtd_name" && flash_eraseall "/dev/$rw_mtd_name"
  else
    # Block device: mkfs the partition
    if command -v "mkfs.$rwfst" >/dev/null 2>&1; then
      "mkfs.$rwfst" -F "$rwdev"
    else
      echo "mkfs.$rwfst not found; will fall back to deleting upperdir contents after mount."
      return 1
    fi
  fi
  return 0
}

if grep -w clean-rwfs-filesystem "$optfile" >/dev/null 2>&1; then
  echo "Cleaning of read-write overlay filesystem requested."
  clear_rwfs || true
fi

if grep -w factory-reset "$optfile" >/dev/null 2>&1; then
  echo "Factory reset requested."
fi

if grep -w copy-base-filesystem-to-ram "$optfile" >/dev/null 2>&1 && \
   test ! -e /run/image-rofs && ! cp "$rodev" /run/image-rofs; then
  # Remove any partial copy to avoid attempted usage later
  if test -e /run/image-rofs; then
    ls -l /run/image-rofs || true
    rm -f /run/image-rofs
  fi
  debug_takeover "Copying $rodev to /run/image-rofs failed."
fi
if test -s /run/image-rofs; then
  rodev=/run/image-rofs
  roopts=$roopts,loop
fi

mount "$rodev" "$rodir" -t "$rofst" -o "$roopts"

# Run fsck for RWFS if available in rofs
if test -x "$rodir$fsck"; then
  for fs in $fslist; do
    mount --bind "$fs" "$rodir/$fs"
  done
  chroot "$rodir" "$fsck" $fsckopts "$rwdev"
  rc=$?
  for fs in $fslist; do
    umount "$rodir/$fs"
  done
  if test $rc -gt 1; then
    echo "[obmc-init] fsck error rc=$rc on $rwdev ($rwfst); printing labels & blkid"
    dump_labels_and_blkid
    debug_takeover "fsck of read-write fs on $rwdev failed (rc=$rc)"
  fi
elif test "$rwfst" != jffs2 -a "$rwfst" != none; then
  echo "No '$fsck' in read-only fs, skipping fsck."
fi

if test "$rwfst" = none; then
  echo "Running with read-write overlay in RAM for this boot."
  echo "No state will be preserved unless flash update performed."
elif ! mount "$rwdev" "$rwdir" -t "$rwfst" -o "$rwopts"; then
  echo "[obmc-init] ERROR: mounting $rwdev as $rwfst at $rwdir failed; printing labels & blkid"
  dump_labels_and_blkid

  msg="$(cat << HERE
Mounting read-write $rwdev filesystem failed. Please fix and run
  mount $rwdev $rwdir -t $rwfst -o $rwopts
or perform a factory reset with the clean-rwfs-filesystem option.
HERE
)"
  debug_takeover "$msg"
fi

# Empty workdir; do not remove workdir itself (RWFS could be full)
if [ -d "$work" ]; then
  find "$work" -maxdepth 1 -mindepth 1 -exec rm -rf '{}' +
fi
mkdir -p "$upper" "$work"

# Opportunistically set a sane BMC date
files="$upper/var/lib/systemd/random-seed $rodir/etc/os-release"
time=$(find $files -exec stat -c %Y {} \; 2>/dev/null | sort -n | tail -n 1 || echo 0)
time=${time:-0}
if [ "$(date +%s 2>/dev/null || echo 0)" -lt "$time" ]; then
  date -s @$(($time + 5)) || true
fi

mount -t overlay -o lowerdir="$rodir",upperdir="$upper",workdir="$work" cow /root

while ! chroot /root /bin/sh -c "test -x '$init' -a -s '$init'"; do
  msg="$(cat << HERE
Unable to confirm /sbin/init is an executable non-empty file
in merged file system mounted at /root.
Change Root test failed!
HERE
)"
  debug_takeover "$msg"
done

for f in $fslist; do
  mount --move "$f" "root/$f"
done

exec switch_root /root "$init"