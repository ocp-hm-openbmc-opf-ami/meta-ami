# Copyright 2025-2026 NXP

require conf/machine/include/arm/armv8-2a/tune-cortexa55.inc

PREFERRED_PROVIDER_virtual/kernel ??= "linux-nxp"
PREFERRED_PROVIDER_virtual/xserver ?= "xserver-xorg"

PREFERRED_PROVIDER_virtual/libomxil ?= "userland"
VIRTUAL-RUNTIME_libomxil = "userland"

#PREFERRED_VERSION_linux-imx ??= "6.12.%"

IMAGE_FSTYPES ?= "tar.bz2 ext3 cpio.gz wic.bz2 wic.bmap"

MACHINEOVERRIDES .= ":nxp"

XSERVER = " \
    xserver-xorg \
    ${@bb.utils.contains("MACHINE_FEATURES", "vc4graphics", "xserver-xorg-extension-glx", "", d)} \
    ${@bb.utils.contains("MACHINE_FEATURES", "vc4graphics", "xf86-video-modesetting", "xf86-video-fbdev", d)} \
    "

RPI_KERNEL_DEVICETREE_OVERLAYS ?= " \
    freescale/${REAL_TIME_EDGE_LINUX_DTS} \
    "

RPI_KERNEL_DEVICETREE ?= " \
    ${REAL_TIME_EDGE_LINUX_DTS} \
    "

KERNEL_DEVICETREE ??= " \
    ${RPI_KERNEL_DEVICETREE_OVERLAYS} \
    "

BMC_LINUX_SRC_INTERNAL = "git://git@bitbucket.sw.nxp.com/lfac/linux-lts-nxp.git;protocol=ssh"
BMC_LINUX_SRC_GITHUB = "git://github.com/nxp-imx/linux-imx.git;protocol=https"

BMC_LINUX_SRC = "${BMC_LINUX_SRC_GITHUB}"
BMC_LINUX_BRANCH = "lf-6.12.y"
BMC_LINUX_SRCREV = "df24f9428e38740256a410b983003a478e72a7c0"
BMC_LINUX_DEFCONFIG ?= "imx_v8_defconfig"

KERNEL_BOOTCMD ??= "bootm"
KERNEL_IMAGETYPE_UBOOT ??= "uImage"
KERNEL_IMAGETYPE_DIRECT ??= "Image"
KERNEL_IMAGETYPE ?= "${@bb.utils.contains('RPI_USE_U_BOOT', '1', \
        '${KERNEL_IMAGETYPE_UBOOT}', '${KERNEL_IMAGETYPE_DIRECT}', d)}"

MACHINE_FEATURES += "apm usbhost keyboard vfat ext2 screen touchscreen alsa bluetooth wifi sdio ${@bb.utils.contains('DISABLE_VC4GRAPHICS', '1', '', 'vc4graphics', d)}"

MACHINE_FEATURES_BACKFILL_CONSIDERED = "rtc"

MACHINE_EXTRA_RRECOMMENDS += "kernel-modules udev-rules-imx"
MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS += "${@oe.utils.conditional('ENABLE_I2C', '1', 'kernel-module-i2c-dev kernel-module-i2c-bcm2708', '', d)}"
MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS += "${@oe.utils.conditional('ENABLE_IR', '1', 'kernel-module-gpio-ir kernel-module-gpio-ir-tx', '', d)}"
MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS += "${@oe.utils.conditional('ENABLE_GPIO_SHUTDOWN', '1', 'gpio-shutdown kernel-module-gpio-keys', '', d)}"

SERIAL_CONSOLES_CHECK ??= "${SERIAL_CONSOLES}"

BOOTFILES_DIR_NAME ?= "bootfiles"

def make_dtb_boot_files(d):
    # KERNEL_DEVICETREE.
    alldtbs = d.getVar('KERNEL_DEVICETREE')

    def transform(dtb):
        base = os.path.basename(dtb)
        if dtb.endswith('dtbo') or base == '${KERNEL_DEVICETREE}':
            return '{};{}'.format(base, dtb)
        elif dtb.endswith('dtb'):
            return base

    return ' '.join([transform(dtb) for dtb in alldtbs.split(' ') if dtb])
