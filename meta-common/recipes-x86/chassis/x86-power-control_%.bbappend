FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:remove = "git://github.com/openbmc/x86-power-control.git;protocol=https;branch=master"

SRC_URI:append = " git://git.ami.com/core/ami-bmc/one-tree/core/x86-power-control.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "99e2d19cf7992f97bc4dd75317822f1dda87e849"
DEPENDS += "bmc-boot-check"
DEPENDS:append = " libpdkhook "
RDEPENDS:${PN}:append = " libpdkhook "
