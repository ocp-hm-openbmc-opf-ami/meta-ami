require u-boot-common-aspeed-sdk_2023.10.inc

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
require ${THISDIR}/aspeed-coprocessor.inc

UBOOT_MAKE_TARGET ?= "DEVICE_TREE=${UBOOT_DEVICETREE}"

require recipes-bsp/u-boot/u-boot-aspeed.inc

DEPENDS += "bc-native dtc-native"
DEPENDS += "${@bb.utils.contains('MACHINE_FEATURES', 'ast-secure', 'aspeed-secure-config-native', '', d)}"

UBOOT_ENV_SIZE:ast-mmc = "0x20000"
UBOOT_ENV:ast-mmc = "u-boot-env"
UBOOT_ENV_SUFFIX:ast-mmc = "bin"
UBOOT_ENV_TXT:ast-mmc = "u-boot-env.txt"

UBOOT_ENV_SIZE:ast-ufs = "0x20000"
UBOOT_ENV:ast-ufs = "u-boot-env"
UBOOT_ENV_SUFFIX:ast-ufs = "bin"
UBOOT_ENV_TXT:ast-ufs = "u-boot-env-ufs.txt"


#Dual Image
SRC_URI:append:ast2700-default = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image', ' file://0001-Add-hw-failsafe-bootsupport-for-ast2700.patch', '', d)}"

SRC_URI:append:ast2700-default = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image', ' file://0001-Fixed-the-erase-method-boot-issue.patch', '', d)}"

DUAL_IMAGE_PATCHES = " file://0001-Fix-for-dual-image-hardware-failsafe-in-ast2700evb.patch \
                     "
SRC_URI:append:ast2700-default = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image', '${DUAL_IMAGE_PATCHES}', '', d)}"

SRC_URI:append = " \
        file://dts-evb-ast2700/ \
        file://disable-kernel-fitimage-signature-verify-via-cptra.cfg \
        file://0001-Software-Secure-Boot-workaround.patch \
    "

do_configure:append (){
    cp ${UNPACKDIR}/dts-evb-ast2700/ast2700-evb.dts ${S}/arch/arm/dts/
}

do_compile:append() {
    if [ -n "${UBOOT_ENV}" ]
    then
        # Generate default environment image
        # add -r parameter if wants redundant environment image
        ${B}/tools/mkenvimage -s ${UBOOT_ENV_SIZE} -o ${B}/${UBOOT_ENV_BINARY} ${UNPACKDIR}/${UBOOT_ENV_TXT}
    fi
}

