FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=core-sync_Intel_LF-bhs-24.29-0;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "5b45bd8a3a01b09bb69110c065385cd3102c204c"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"

EXTRA_OEMESON += " -Dipmi-firewall=true"

#To Enable Configurable fru 
#EXTRA_OEMESON += " -Dconfigurable-fru=true"

