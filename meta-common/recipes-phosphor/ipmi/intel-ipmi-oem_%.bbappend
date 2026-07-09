FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=master;protocol=https;name=override;"

SRCREV_FORMAT = "override"
SRCREV_override = "9f2f6e3491db93e7a8adc5c34436e890e63519a6"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"

EXTRA_OEMESON += " -Dipmi-firewall=true"
EXTRA_OEMESON += "-Dapisensor=enabled"

# it is the temporary solution for AMD platform
EXTRA_OEMESON += "${@bb.utils.contains('MACHINE', 'amd-chalupa', ' -Dconfigurable-fru=true', '', d)}"

EXTRA_OEMESON:append = "${@' -Dstatic-sensor-number=enabled' if d.getVar('STATIC_SENSOR_NUMBER_ENABLE') == '1' else ' -Dstatic-sensor-number=disabled'}"
