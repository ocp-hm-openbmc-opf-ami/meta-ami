FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-dbus-interfaces;protocol=https;branch=main;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "aa72ae32dd7b95f20ef0a8576ca24fb03fd3b417"

include ${@bb.utils.contains('BBFILE_COLLECTIONS', 'nvidia-layer', 'phosphor-dbus-interfaces_nv.inc', '', d)}

EXTRA_OEMESON += "-Ddata_com_ami=true"
EXTRA_OEMESON += "-Ddata_org_open_power=true"

