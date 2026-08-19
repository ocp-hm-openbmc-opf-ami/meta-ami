require bootmcu-spl.inc
require recipes-bsp/u-boot/u-boot-common-aspeed-sdk_${PV}.inc

SRC_URI += "file://spl-malloc-simple.cfg"
SRC_URI += "file://0001-board-ibex_ast2700-Add-PHY3-XHCI-USB-IP-initialization.patch"