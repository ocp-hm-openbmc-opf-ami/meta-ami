FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:remove = "git://github.com/openbmc/x86-power-control.git;protocol=https;branch=master"

SRC_URI  += "git://git.ami.com/core/ami-bmc/one-tree/core/x86-power-control.git;branch=master;protocol=https;name=override; "
SRCREV_FORMAT = "override"
SRCREV = "0611382dcb54a19de3d3728870942934af0e7660"
DEPENDS += "bmc-boot-check"
DEPENDS:append = " libpdkhook "
RDEPENDS:${PN}:append = " libpdkhook "
