FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "8b416dd2c52a36835771477e55d9fb33c21652c3"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"
