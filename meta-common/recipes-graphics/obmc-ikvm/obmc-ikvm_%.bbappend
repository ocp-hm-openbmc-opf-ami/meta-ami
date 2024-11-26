FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/obmc-ikvm;branch=main;protocol=https"
SRCREV = "3d9d8f0dd692c833ae93f70dd8f84d2692f9c374"

SYSTEMD_SERVICE:${PN} += "start-ipkvm.socket"

FILES:${PN} += "${systemd_system_unitdir}/start-ipkvm.service.d"
