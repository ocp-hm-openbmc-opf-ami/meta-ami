FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:remove = "git://github.com/openbmc/x86-power-control.git;protocol=https;branch=master"

SRC_URI:append = " git://github.com/ocp-hm-openbmc-opf-ami/x86-power-control.git;protocol=https;branch=master;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "aa2defc9a920a2e09d37afba6af3da40d5bc4de7"
DEPENDS += "bmc-boot-check"
DEPENDS:append = " libpdkhook "
RDEPENDS:${PN}:append = " libpdkhook "
