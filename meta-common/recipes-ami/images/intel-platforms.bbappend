inherit obmc-phosphor-signining

ROOTFS_POSTPROCESS_COMMAND:remove = "set_user_groupdo_populate_static_lic;"
ROOTFS_POSTPROCESS_COMMAND:append = " set_user_group do_populate_static_lic "


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

enable_radius_nsswitch() {
    sed -i 's/\(\(passwd\|group\):\s*\).*/\1files systemd ldap radius/' \
        "${IMAGE_ROOTFS}${sysconfdir}/nsswitch.conf"
    sed -i 's/\(shadow:\s*\).*/\1files ldap radius/' \
        "${IMAGE_ROOTFS}${sysconfdir}/nsswitch.conf"
    sed -i 's/enable-cache\s*passwd\s*yes/enable-cache            passwd          no/' ${IMAGE_ROOTFS}/etc/nscd.conf

}

ROOTFS_POSTPROCESS_COMMAND += "${@bb.utils.contains('IMAGE_INSTALL', 'radiusclient-ng', 'enable_radius_nsswitch; ', '', d)}"

ROOTFS_POSTPROCESS_COMMAND += "write_flash_size_to_file; "

