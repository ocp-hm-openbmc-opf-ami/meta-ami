FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "03285ce4ec120099ea5ef7beea905e067e24cfdd"

PACKAGECONFIG:append = " non-intel-platforms"

EXTRA_OEMESON += " -Dipmi-firewall=true"
