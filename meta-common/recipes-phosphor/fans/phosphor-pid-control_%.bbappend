FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-pid-control.git;branch=integrate-onetree-3.1.1;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "dcf4e0bd635b9aa76c1524d524e52b47d4945f8d"
