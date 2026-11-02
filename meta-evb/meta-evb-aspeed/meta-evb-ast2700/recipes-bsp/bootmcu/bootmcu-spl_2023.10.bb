require bootmcu-spl.inc
require recipes-bsp/u-boot/u-boot-common-aspeed-sdk_2023.10.inc

BRANCH = "onetree-dev-v2023.10"
SRC_URI = "git://git.ami.com/core/ami-bmc/base-tech/u-boot-onetree.git;protocol=https;branch=onetree-dev-v2023.10 "

SRCREV = "f3b060fb8979b5e539bb08d1ff431cfa47e4b961"

SRC_URI += "file://spl-malloc-simple.cfg"
SRC_URI += "file://0001-board-ibex_ast2700-Add-PHY3-XHCI-USB-IP-initialization.patch"
