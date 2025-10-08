FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/intel-ipmi-oem;protocol=https;branch=master;name=override;"
SRC_URI += " \
             file://0001-OT-14429-oem-update-username-validation-check.patch \
           "
SRCREV_FORMAT = "override"
SRCREV_override = "8ea90bab0f9b55613c8e357d0b09d3f312102245"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"

EXTRA_OEMESON += " -Dipmi-firewall=true"

# it is the temporary solution for AMD platform
EXTRA_OEMESON += "${@bb.utils.contains('MACHINE', 'amd-chalupa', ' -Dconfigurable-fru=true', '', d)}"
