FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "e76ced8949183c7322b5d082d5a3a0d8b823cfc5"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"

EXTRA_OEMESON += " -Dipmi-firewall=true"
