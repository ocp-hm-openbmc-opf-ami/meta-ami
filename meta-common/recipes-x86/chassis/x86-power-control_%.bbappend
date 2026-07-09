FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:remove = "git://github.com/openbmc/x86-power-control.git;protocol=https;branch=master"

SRC_URI:append = " git://git.ami.com/core/ami-bmc/one-tree/core/x86-power-control.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "c59d7a605ed3cd7805ad1f40c600d6ec87773d62"
DEPENDS += "bmc-boot-check"
DEPENDS:append = " libpdkhook "
RDEPENDS:${PN}:append = " libpdkhook "
