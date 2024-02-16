FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "148c35ee6fa6dbaffab5c4872460ec04f34e249b"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"
