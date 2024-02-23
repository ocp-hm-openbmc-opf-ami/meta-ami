FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=Add_dbus_for_snmp;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "5670fdd90616f32dc99f568238ef5306f37d9df8"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"
