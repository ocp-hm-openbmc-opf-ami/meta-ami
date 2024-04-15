FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "9740066d11c83acd3816f885c849ca763cd0a572"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"

EXTRA_OEMESON += " -Dipmi-firewall=true"
