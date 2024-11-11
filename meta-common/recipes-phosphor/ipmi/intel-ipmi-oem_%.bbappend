FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "4ed21c3b496a1c504c43e372b44d690277b49a8f"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"

EXTRA_OEMESON += " -Dipmi-firewall=true"

#To Enable Configurable fru 
#EXTRA_OEMESON += " -Dconfigurable-fru=true"

