
write_flash_size_to_file() {
    flash_size_kb="${FLASH_SIZE}"
    image_size_bytes=$(expr "${flash_size_kb}" \* 1024)
    image_size_hex=$(printf "0x%x" "${image_size_bytes}")
    fw_size_file="${IMAGE_ROOTFS}/etc/FWSize"

    if [ ! -d "${IMAGE_ROOTFS}/etc" ]; then
        echo "Directory ${IMAGE_ROOTFS}/etc does not exist. Creating it."
        mkdir -p "${IMAGE_ROOTFS}/etc"
    fi

    echo "${image_size_hex}" > "${fw_size_file}"
}

# Disable root login when debug-tweaks is not enabled
python __anonymous() {
    if not bb.utils.contains_any("EXTRA_IMAGE_FEATURES", ["debug-tweaks", "allow-root-login"], True, False, d):
        d.appendVar("EXTRA_USERS_PARAMS:pn-obmc-phosphor-image", " usermod -p \"!\" root;")
}

enable_radius_nsswitch() {
    sed -i 's/\(\(passwd\|group\):\s*\).*/\1files systemd ldap radius/' \
        "${IMAGE_ROOTFS}${sysconfdir}/nsswitch.conf"
    sed -i 's/\(shadow:\s*\).*/\1files ldap radius/' \
        "${IMAGE_ROOTFS}${sysconfdir}/nsswitch.conf"
    sed -i 's/enable-cache\s*passwd\s*yes/enable-cache            passwd          no/' "${IMAGE_ROOTFS}/etc/nscd.conf"
}

ROOTFS_POSTPROCESS_COMMAND += "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-radius-client', 'enable_radius_nsswitch; ', '', d)}"

ROOTFS_POSTPROCESS_COMMAND += "write_flash_size_to_file; "

inherit obmc-onetree-apps
