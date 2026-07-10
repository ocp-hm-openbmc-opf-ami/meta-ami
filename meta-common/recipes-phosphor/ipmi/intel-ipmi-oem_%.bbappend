FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/intel-ipmi-oem;protocol=https;branch=main;name=override;"
SRC_URI += " \
             file://0001-OT-14429-oem-update-username-validation-check.patch \
           "
SRCREV_FORMAT = "override"
SRCREV_override = "55a1c5e170fd4cfa317c8c6c3c38acc048e95415"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"

EXTRA_OEMESON += " -Dipmi-firewall=true"
EXTRA_OEMESON += "-Dapisensor=enabled"

# it is the temporary solution for AMD platform
EXTRA_OEMESON += "${@bb.utils.contains('MACHINE', 'amd-chalupa', ' -Dconfigurable-fru=true', '', d)}"

EXTRA_OEMESON:append = "${@' -Dstatic-sensor-number=enabled' if d.getVar('STATIC_SENSOR_NUMBER_ENABLE') == '1' else ' -Dstatic-sensor-number=disabled'}"
