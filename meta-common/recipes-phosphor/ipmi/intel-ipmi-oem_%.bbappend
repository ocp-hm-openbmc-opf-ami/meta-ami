FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "dc4c8684b7b1b7506250a43db4a35610254f71de"

PACKAGECONFIG:append = " non-intel-platforms"

EXTRA_OEMESON += " -Dipmi-firewall=true"
