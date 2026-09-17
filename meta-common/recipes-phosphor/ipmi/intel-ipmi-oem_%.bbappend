FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/intel-ipmi-oem;protocol=https;branch=master;name=override;"

SRCREV_FORMAT = "override"
SRCREV_override = "5bbc68ffa39ebda39dd0fb53ce718ae98c38b3a3"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"

EXTRA_OEMESON += " -Dipmi-firewall=true"
EXTRA_OEMESON += "-Dapisensor=enabled"

# it is the temporary solution for AMD platform
EXTRA_OEMESON += "${@bb.utils.contains('MACHINE', 'amd-chalupa', ' -Dconfigurable-fru=true', '', d)}"

EXTRA_OEMESON:append = "${@' -Dstatic-sensor-number=enabled' if d.getVar('STATIC_SENSOR_NUMBER_ENABLE') == '1' else ' -Dstatic-sensor-number=disabled'}"
