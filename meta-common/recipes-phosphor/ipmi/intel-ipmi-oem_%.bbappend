FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "604f5aab11abddb77a904cd488577bb4bbf0ad1a"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"
