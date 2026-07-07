require bootmcu-spl.inc
require recipes-bsp/u-boot/u-boot-common-aspeed-sdk_${PV}.inc

SRC_URI += "file://spl-malloc-simple.cfg"
