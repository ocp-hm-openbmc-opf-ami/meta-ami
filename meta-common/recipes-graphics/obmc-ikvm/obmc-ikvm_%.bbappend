FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/obmc-ikvm;protocol=https;branch=main"


SRCREV = "cce6eeae536086e1df9e4e3d46ae340740d713f0"

SYSTEMD_SERVICE:${PN} += "start-ipkvm.socket"

FILES:${PN} += "${systemd_system_unitdir}/start-ipkvm.service.d"

SYSTEMD_SERVICE:${PN} += "start-dummy-ipkvm-client.service"

