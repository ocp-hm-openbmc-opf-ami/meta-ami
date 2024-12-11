FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/obmc-ikvm;branch=main;protocol=https"
SRCREV = "76c545c6051de06180d79654abe2c7e70ef87acb"

SYSTEMD_SERVICE:${PN} += "start-ipkvm.socket"

FILES:${PN} += "${systemd_system_unitdir}/start-ipkvm.service.d"
