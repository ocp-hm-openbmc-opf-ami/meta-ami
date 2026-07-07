FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-dbus-interfaces.git;branch=main;protocol=https;name=override;"

SRCREV_FORMAT = "override"
SRCREV_override = "05f774bed9316c45c1295e4ad46cb80b62185a46"

include ${@bb.utils.contains('BBFILE_COLLECTIONS', 'nvidia-layer', 'phosphor-dbus-interfaces_nv.inc', '', d)}

EXTRA_OEMESON += "-Ddata_com_ami=true"
EXTRA_OEMESON += "-Ddata_org_open_power=true"

