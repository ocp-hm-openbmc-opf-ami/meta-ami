FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "f6411b47a8b048f9939cb134a5cb56ff1d3877d2"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"

EXTRA_OEMESON += " -Dipmi-firewall=true"

#To Enable Configurable fru 
#EXTRA_OEMESON += " -Dconfigurable-fru=true"

