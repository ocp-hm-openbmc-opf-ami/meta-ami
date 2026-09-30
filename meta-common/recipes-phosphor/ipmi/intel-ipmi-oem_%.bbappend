FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/intel-ipmi-oem;protocol=https;branch=integrate-onetree-latest;name=override;"

SRCREV_FORMAT = "override"
SRCREV_override = "768c35f40d94d5dcb0ed1668be7c9017b69ea4df"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"

EXTRA_OEMESON += " -Dipmi-firewall=true"
EXTRA_OEMESON += "-Dapisensor=enabled"

# it is the temporary solution for AMD platform
EXTRA_OEMESON += "${@bb.utils.contains('MACHINE', 'amd-chalupa', ' -Dconfigurable-fru=true', '', d)}"

EXTRA_OEMESON:append = "${@' -Dstatic-sensor-number=enabled' if d.getVar('STATIC_SENSOR_NUMBER_ENABLE') == '1' else ' -Dstatic-sensor-number=disabled'}"
