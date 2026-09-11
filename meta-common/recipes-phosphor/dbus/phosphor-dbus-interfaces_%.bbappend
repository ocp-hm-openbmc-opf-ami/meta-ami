FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-dbus-interfaces;protocol=https;branch=integrate-onetree-3.1.1;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "297a61846f17b164643b7771819f4831dee685d2"

include ${@bb.utils.contains('BBFILE_COLLECTIONS', 'nvidia-layer', 'phosphor-dbus-interfaces_nv.inc', '', d)}

EXTRA_OEMESON += "-Ddata_com_ami=true"
EXTRA_OEMESON += "-Ddata_org_open_power=true"

do_write_config[depends] = ""
addtask write_config after do_unpack do_patch before do_configure
