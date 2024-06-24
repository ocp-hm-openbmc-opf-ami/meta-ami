FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=BMCFirmwareHealth-discrete-sensor;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "39b8ec96e54d6cee947fa95d26882a8e77834187"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"

EXTRA_OEMESON += " -Dipmi-firewall=true"
