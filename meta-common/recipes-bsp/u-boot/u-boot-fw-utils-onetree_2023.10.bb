SUMMARY = "U-Boot bootloader fw_printenv/setenv utilities"

BRANCH = "onetree-dev-v2023.10"
SRC_URI = "git://git.ami.com/core/ami-bmc/base-tech/u-boot-onetree.git;protocol=https;branch=onetree-dev-v2023.10 "

SRCREV = "f3b060fb8979b5e539bb08d1ff431cfa47e4b961"

LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=2ca5f2c35c8cc335f0a19756634782f1"

S = "${WORKDIR}/git"
PV = "v2023.10+git${SRCPV}"
