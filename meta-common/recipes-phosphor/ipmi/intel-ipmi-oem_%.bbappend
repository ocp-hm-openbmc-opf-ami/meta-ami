FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "b39f01302064431499a97c2f62698df76983ed7d"

PACKAGECONFIG:append = " non-intel-platforms"

EXTRA_OEMESON += " -Dipmi-firewall=true"
