FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/obmc-ikvm;branch=main;protocol=https"
SRCREV = "cd5a03ce83f0cc984e526e9884800e21a9e1f4fd"

SYSTEMD_SERVICE:${PN} += "start-ipkvm.socket"

FILES:${PN} += "${systemd_system_unitdir}/start-ipkvm.service.d"
