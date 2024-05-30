FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "f0b446c861393ad621f10beab288dab2fb284e04"

PACKAGECONFIG:append = " non-intel-platforms"

EXTRA_OEMESON += " -Dipmi-firewall=true"
