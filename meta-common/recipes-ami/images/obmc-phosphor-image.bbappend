
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

ROOTFS_POSTPROCESS_COMMAND += "write_flash_size_to_file; "

