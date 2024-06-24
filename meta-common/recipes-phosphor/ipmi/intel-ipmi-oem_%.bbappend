FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=BMCFirmwareHealth-discrete-sensor;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "d8b3ab3c199f948d0a46030645b07a5dbf4bf8e2"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"

EXTRA_OEMESON += " -Dipmi-firewall=true"
