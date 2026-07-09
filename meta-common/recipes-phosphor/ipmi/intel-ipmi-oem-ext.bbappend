FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem-ext.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "382aa8c222a301284b1a3bc183b31f3a7f9fd192"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"

EXTRA_OEMESON += " -Dipmi-firewall=true"
EXTRA_OEMESON += "-Dapisensor=enabled"
EXTRA_OEMESON += " -Ddisable-special-mode=true"

# it is the temporary solution for AMD platform
EXTRA_OEMESON += "${@bb.utils.contains('MACHINE', 'amd-chalupa', ' -Dconfigurable-fru=true', '', d)}"
FILES:${PN}:append = " ${datadir}/intel-ipmi-oem"
