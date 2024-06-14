FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "fc5297eb91e9719b5f498b83816bec858860dfca"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"

EXTRA_OEMESON += " -Dipmi-firewall=true"
