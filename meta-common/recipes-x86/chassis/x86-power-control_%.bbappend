FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:remove = "git://github.com/openbmc/x86-power-control.git;protocol=https;branch=master"

SRC_URI  += "git://github.com/ocp-hm-openbmc-opf-ami/x86-power-control.git;protocol=https;branch=main;name=override; "
SRCREV_FORMAT = "override"
SRCREV = "0611382dcb54a19de3d3728870942934af0e7660"
DEPENDS += "bmc-boot-check"
DEPENDS:append = " libpdkhook "
RDEPENDS:${PN}:append = " libpdkhook "
