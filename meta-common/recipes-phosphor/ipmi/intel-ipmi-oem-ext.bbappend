FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/intel-ipmi-oem-ext.git;branch=integrate-onetree-latest;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "3d01405a10bf956c46f9486d7368f683c42ad904"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"

EXTRA_OEMESON += " -Dipmi-firewall=true"
EXTRA_OEMESON += "-Dapisensor=enabled"
EXTRA_OEMESON += " -Ddisable-special-mode=true"

# it is the temporary solution for AMD platform
EXTRA_OEMESON += "${@bb.utils.contains('MACHINE', 'amd-chalupa', ' -Dconfigurable-fru=true', '', d)}"
FILES:${PN}:append = " ${datadir}/intel-ipmi-oem"
