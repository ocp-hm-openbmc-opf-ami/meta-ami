FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "56452c1bf1dae13cb9774db273e2163d2ca0f850"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"

EXTRA_OEMESON += " -Dipmi-firewall=true"

#To Enable Configurable fru 
EXTRA_OEMESON += " -Dconfigurable-fru=true"

