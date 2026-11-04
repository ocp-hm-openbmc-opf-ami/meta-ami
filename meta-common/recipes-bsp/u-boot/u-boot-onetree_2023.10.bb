DESCRIPTION = "U-boot for Nuvoton NPCM7xx/NPCM8xx and Aspeed Baseboard Management Controllers"

SECTION = "bootloaders"
DEPENDS += "flex-native bison-native"

LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=2ca5f2c35c8cc335f0a19756634782f1"

BRANCH = "onetree-dev-v2023.10"
SRC_URI = "git://git.ami.com/core/ami-bmc/base-tech/u-boot-onetree.git;protocol=https;branch=onetree-dev-v2023.10 "

SRCREV = "f3b060fb8979b5e539bb08d1ff431cfa47e4b961"

PV = "v2023.10+git"

PROVIDES += "u-boot"

S = "${WORKDIR}/git"
B = "${WORKDIR}/build"

