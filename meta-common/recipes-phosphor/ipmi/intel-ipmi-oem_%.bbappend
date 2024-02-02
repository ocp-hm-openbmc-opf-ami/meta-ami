FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "d39ef9f25b72eac74d0f3941d0cc072c98b3b9a8"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"
