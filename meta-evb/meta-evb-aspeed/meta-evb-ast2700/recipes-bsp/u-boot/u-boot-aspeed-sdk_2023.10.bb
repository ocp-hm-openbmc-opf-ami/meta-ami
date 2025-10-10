require u-boot-common-aspeed-sdk_${PV}.inc

UBOOT_MAKE_TARGET ?= "DEVICE_TREE=${UBOOT_DEVICETREE}"

require recipes-bsp/u-boot/u-boot-aspeed.inc

PROVIDES += "u-boot"
DEPENDS += "bc-native dtc-native"

python __anonymous() {
    if d.getVar("SPL_SIGN_ENABLE") == "1":
        d.appendVar("DEPENDS", " bootmcu-spl")
}

UBOOT_ENV_SIZE:ast-mmc = "0x20000"
UBOOT_ENV:ast-mmc = "u-boot-env"
UBOOT_ENV_SUFFIX:ast-mmc = "bin"
UBOOT_ENV_TXT:ast-mmc = "u-boot-env.txt"

UBOOT_ENV_SIZE:ast-ufs = "0x20000"
UBOOT_ENV:ast-ufs = "u-boot-env"
UBOOT_ENV_SUFFIX:ast-ufs = "bin"
UBOOT_ENV_TXT:ast-ufs = "u-boot-env-ufs.txt"

do_compile:append() {
    if [ -n "${UBOOT_ENV}" ]
    then
        # Generate default environment image
        # add -r parameter if wants redundant environment image
        ${B}/tools/mkenvimage -s ${UBOOT_ENV_SIZE} -o ${WORKDIR}/${UBOOT_ENV_BINARY} ${WORKDIR}/${UBOOT_ENV_TXT}
    fi
}
