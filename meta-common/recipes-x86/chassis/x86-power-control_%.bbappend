FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:remove = "git://github.com/openbmc/x86-power-control.git;protocol=https;branch=master"

SRC_URI:append  += "git://github.com/ocp-hm-openbmc-opf-ami/x86-power-control.git;protocol=https;branch=integrate-onetree-3.1.1;name=override; "
SRCREV_FORMAT = "override"
SRCREV_override = "4d54f104baf90166fab5963f35be5e059f5c056a"
DEPENDS += "bmc-boot-check"
DEPENDS:append = " libpdkhook "
RDEPENDS:${PN}:append = " libpdkhook "
