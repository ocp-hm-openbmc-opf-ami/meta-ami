FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:remove = "git://github.com/openbmc/x86-power-control.git;protocol=https;branch=master"

SRC_URI  += "git://github.com/ocp-hm-openbmc-opf-ami/x86-power-control.git;protocol=https;branch=main;name=override"
SRCREV_FORMAT = "override"
SRCREV = "1b4186f122f8fe3fa745d4e7c9a448cbccccadf2"
DEPENDS += "bmc-boot-check"
DEPENDS:append = " libpdkhook "
RDEPENDS:${PN}:append = " libpdkhook "
