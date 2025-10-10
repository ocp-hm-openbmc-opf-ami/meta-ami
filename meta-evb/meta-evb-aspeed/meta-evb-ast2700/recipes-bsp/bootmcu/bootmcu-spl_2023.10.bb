require bootmcu-spl.inc
require recipes-bsp/u-boot/u-boot-common-aspeed-sdk_${PV}.inc

FILESEXTRAPATHS:prepend:= "${THISDIR}/files:"

python __anonymous() {
    if d.getVar("SPL_SIGN_ENABLE") == "1":
        d.appendVar("DEPENDS", " u-boot-mkimage-native")
}
