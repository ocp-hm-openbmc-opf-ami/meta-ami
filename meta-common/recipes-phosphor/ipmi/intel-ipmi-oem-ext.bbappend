FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem-ext.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "20a0f71b01ac4c607de640fef8f41655c0e44002"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"

EXTRA_OEMESON += " -Dipmi-firewall=true"
EXTRA_OEMESON += "-Dapisensor=enabled"
EXTRA_OEMESON += " -Ddisable-special-mode=true"

# it is the temporary solution for AMD platform
EXTRA_OEMESON += "${@bb.utils.contains('MACHINE', 'amd-chalupa', ' -Dconfigurable-fru=true', '', d)}"
FILES:${PN}:append = " ${datadir}/intel-ipmi-oem"
