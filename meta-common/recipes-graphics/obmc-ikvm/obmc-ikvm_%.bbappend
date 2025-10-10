FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/obmc-ikvm;protocol=https;branch=main"


SRCREV = "5d84e976e1025f34b04fe40edab75be3609c8807"

SYSTEMD_SERVICE:${PN} += "start-ipkvm.socket"

FILES:${PN} += "${systemd_system_unitdir}/start-ipkvm.service.d"

SYSTEMD_SERVICE:${PN} += "start-dummy-ipkvm-client.service"

