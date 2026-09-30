FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-dbus-interfaces;protocol=https;branch=integrate-onetree-latest;name=override;"

SRCREV_FORMAT = "override"
SRCREV_override = "abe77c12fc407f16b913f0e87ce138623bc5daac"

include ${@bb.utils.contains('BBFILE_COLLECTIONS', 'nvidia-layer', 'phosphor-dbus-interfaces_nv.inc', '', d)}

EXTRA_OEMESON += "-Ddata_com_ami=true"
EXTRA_OEMESON += "-Ddata_org_open_power=true"

do_write_config[depends] = ""
addtask write_config after do_unpack do_patch before do_configure
