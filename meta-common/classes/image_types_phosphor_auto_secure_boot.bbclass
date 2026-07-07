# Base image class extension, inlined into every image.

# Phosphor image types
#
# New image types based on DTS partition information
#

# Image composition
FLASH_FULL_IMAGE ?= "fitImage-rootfs-${MACHINE}.bin"

IMAGE_BASETYPE ?= "squashfs-xz"
OVERLAY_BASETYPE ?= "jffs2"

IMAGE_TYPES += "mtd-auto"

IMAGE_TYPEDEP:mtd-auto = "${IMAGE_BASETYPE}"
IMAGE_TYPES_MASKED += "mtd-auto"
FLASH_UBOOT_SPL_IMAGE ?= "u-boot-spl"
FLASH_UBOOT_IMAGE ?= "u-boot"
image_dst ?= "image-u-boot"
# Flash characteristics in KB unless otherwise noted
python() {
    types = d.getVar('IMAGE_FSTYPES', True).split()

    # TODO: find partition list in DTS
    d.setVar('FLASH_UBOOT_OFFSET', str(0))
    # Set alert size to 8K ( 2 erase sectors of flash)
    d.setVar('IMAGE_ALERT_SIZE', str(8*1024))
    d.setVar('UBOOT_SEC_SIZE', str(512*1024))
    if 'intel-secboot' in types:
        d.setVar('FLASH_SIZE', str(128*1024))
        d.setVar('FIT_SECTOR_SIZE', str(0x1f00000))
        DTB_FULL_FIT_IMAGE_OFFSETS = [0xb00000, 0x040a0000]
    else:
        d.setVar('FLASH_SIZE', str(64*1024))
        d.setVar('FIT_SECTOR_SIZE', str(0x1b80000))
        DTB_FULL_FIT_IMAGE_OFFSETS = [0x80000, 0x2480000]

    d.setVar('FLASH_RUNTIME_OFFSETS', ' '.join(
        [str(int(x/1024)) for x in DTB_FULL_FIT_IMAGE_OFFSETS]
        )
    )
}

mk_nor_image() {
        image_dst="$1"
        image_size_kb=$2
        dd if=/dev/zero bs=1k count=$image_size_kb \
                | tr '\000' '\377' > $image_dst
}

do_generate_auto() {
    bbdebug 1 "do_generate_auto IMAGE_TYPES=${IMAGE_TYPES} size=${FLASH_SIZE}KB (${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.auto.mtd)"
    # Assemble the flash image
    mk_nor_image ${IMGDEPLOYDIR}/${IMAGE_NAME}.auto.mtd ${FLASH_SIZE}

    uboot_offset=${FLASH_UBOOT_OFFSET}

    dd bs=1k conv=notrunc seek=${FLASH_UBOOT_OFFSET} \
        if=${DEPLOY_DIR_IMAGE}/${FLASH_UBOOT_SPL_IMAGE}.${UBOOT_SUFFIX} \
        of=${DEPLOY_DIR_IMAGE}/${image_dst}
    uboot_offset=${FLASH_UBOOT_SPL_SIZE}
    dd bs=1k conv=notrunc seek=${uboot_offset} \
        if=${DEPLOY_DIR_IMAGE}/${FLASH_UBOOT_IMAGE}.${UBOOT_SUFFIX} \
        of=${DEPLOY_DIR_IMAGE}/${image_dst}
    dd bs=1k conv=notrunc seek=${FLASH_UBOOT_OFFSET} \
        if=${DEPLOY_DIR_IMAGE}/${image_dst} \
        of=${IMGDEPLOYDIR}/${IMAGE_NAME}.auto.mtd
    dd bs=1k conv=notrunc seek=${FLASH_UBOOT_B_OFFSET} \
        if=${DEPLOY_DIR_IMAGE}/${image_dst} \
        of=${IMGDEPLOYDIR}/${IMAGE_NAME}.auto.mtd
    FLASH_UBOOT_IMAGE_NAME=${DEPLOY_DIR_IMAGE}/${image_dst}

    UBOOT_IMAGE_SIZE=$(du --apparent-size --block-size=1  \
           $(readlink -f "${FLASH_UBOOT_IMAGE_NAME}") \
          | awk '{ print $1}')

    if [ ${UBOOT_SEC_SIZE}  -gt $UBOOT_IMAGE_SIZE ]; then
        free_space=$(expr ${UBOOT_SEC_SIZE} - $UBOOT_IMAGE_SIZE)
        if [ $free_space -lt ${IMAGE_ALERT_SIZE} ] ; then
            bbwarn "u-boot sector free space $free_space bytes is less than the threshold ${IMAGE_ALERT_SIZE} bytes"
        fi
    else
        bberror "u-boot sector size ${UBOOT_SEC_SIZE} bytes is smaller than image size ${UBOOT_IMAGE_SIZE} bytes"
    fi

    FIT_IMAGE_SIZE=$(du --apparent-size --block-size=1  \
           $(readlink -f "${DEPLOY_DIR_IMAGE}/${FLASH_FULL_IMAGE}") \
          | awk '{ print $1}')

    if [ ${FIT_SECTOR_SIZE}  -gt $FIT_IMAGE_SIZE ]; then
        free_space=$(expr ${FIT_SECTOR_SIZE} - $FIT_IMAGE_SIZE)
        if [ $free_space -lt ${IMAGE_ALERT_SIZE} ] ; then
            bbwarn "FIT Image sector free space $free_space bytes is less than the threshold ${IMAGE_ALERT_SIZE} bytes"
        fi
    else
        bberror "FIT Image sector size ${FIT_SECTOR_SIZE} bytes is smaller than image size ${FIT_IMAGE_SIZE} bytes"
    fi

    for OFFSET in ${FLASH_RUNTIME_OFFSETS}; do
        dd bs=1k conv=notrunc seek=${OFFSET} \
            if=${DEPLOY_DIR_IMAGE}/${FLASH_FULL_IMAGE} \
            of=${IMGDEPLOYDIR}/${IMAGE_NAME}.auto.mtd
    done

    ln ${IMGDEPLOYDIR}/${IMAGE_NAME}.auto.mtd \
        ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.auto.mtd
    ln -sf ${IMAGE_NAME}.auto.mtd ${DEPLOY_DIR_IMAGE}/image-mtd
    ln -sf ${IMAGE_NAME}.auto.mtd ${DEPLOY_DIR_IMAGE}/OBMC-${@ do_get_version(d)}.ROM
}
do_generate_auto[dirs] = "${S}/auto"
do_generate_auto[depends] += " \
        ${PN}:do_image_${@d.getVar('IMAGE_BASETYPE', True).replace('-', '_')} \
        virtual/kernel:do_deploy \
        u-boot:do_populate_sysroot \
        "

python() {
    types = d.getVar('IMAGE_FSTYPES', True).split()

    if 'mtd-auto' in types:
        bb.build.addtask(# task, depends_on_task, task_depends_on, d )
                'do_generate_auto',
                'do_build',
                'do_image_complete', d)
}
