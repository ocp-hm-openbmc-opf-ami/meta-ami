DESCRIPTION = "Generate recovery image via UART for ASPEED BMC SoCs"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${ASPEEDSDKBASE}/LICENSE;md5=a3740bd0a194cd6dcafdc482a200a56f"
PACKAGE_ARCH = "${MACHINE_ARCH}"

PR = "r0"

DEPENDS = "aspeed-image-tools-native"

do_patch[noexec] = "1"
do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_install[noexec] = "1"

inherit deploy

# Image composition
SPL_IMAGE ?= "u-boot-spl.bin"
RECOVERY_SOURCE_IMAGE ?= "recovery_source.bin"
RECOVERY_OUTPUT_IMAGE ?=  "recovery_${SPL_IMAGE}"

OUTPUT_IMAGE_DIR ?= "${S}/output"
SOURCE_IMAGE_DIR ?= "${S}/source"

do_deploy () {
    if [ "${SOC_FAMILY}" = "aspeed-g7" ]; then
        if [ -z ${BOOTMCU_FW_BINARY} ]; then
            bbfatal "Boot from UART mode only support BootMCU SPL"
        fi
    elif [ "${SOC_FAMILY}" = "aspeed-g6" ] ; then
        if [ -z ${SPL_BINARY} ]; then
            bbfatal "Boot from UART mode only support SPL"
        fi
    else
        bbfatal "Unsupport Machine"
    fi

    rm -rf ${SOURCE_IMAGE_DIR}
    rm -rf ${OUTPUT_IMAGE_DIR}
    install -d ${SOURCE_IMAGE_DIR}
    install -d ${OUTPUT_IMAGE_DIR}

    # Install SPL into source directory and generate source image
    install -m 0644 ${DEPLOY_DIR_IMAGE}/${SPL_IMAGE} ${SOURCE_IMAGE_DIR}

    if [ "${SOC_FAMILY}" = "aspeed-g7" ]; then
        dd bs=1 count=128 if=/dev/zero  | tr '\000' '\377' > ${SOURCE_IMAGE_DIR}/${RECOVERY_SOURCE_IMAGE}
        dd bs=1 seek=128 conv=notrunc if=${SOURCE_IMAGE_DIR}/${SPL_IMAGE} of=${SOURCE_IMAGE_DIR}/${RECOVERY_SOURCE_IMAGE}
    elif [ "${SOC_FAMILY}" = "aspeed-g6" ] ; then
        install -m 0644 ${SOURCE_IMAGE_DIR}/${SPL_IMAGE} ${SOURCE_IMAGE_DIR}/${RECOVERY_SOURCE_IMAGE}
    fi

    # Generate recovery image via UART
    python3 ${STAGING_BINDIR_NATIVE}/gen_uart_booting_image.py ${SOURCE_IMAGE_DIR}/${RECOVERY_SOURCE_IMAGE} ${OUTPUT_IMAGE_DIR}/${RECOVERY_OUTPUT_IMAGE}

    # Deploy recovery image via UART
    install -d ${DEPLOYDIR}
    install -m 644 ${OUTPUT_IMAGE_DIR}/${RECOVERY_OUTPUT_IMAGE} ${DEPLOYDIR}/.
}

do_deploy[depends] += " \
    virtual/kernel:do_deploy \
    virtual/bootloader:do_deploy \
    ${@bb.utils.contains('MACHINE_FEATURES', 'ast-bootmcu', 'bootmcu-fw:do_deploy', '', d)} \
    "

addtask deploy before do_build after do_compile
