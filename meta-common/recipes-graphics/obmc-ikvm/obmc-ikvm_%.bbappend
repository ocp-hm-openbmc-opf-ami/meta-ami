FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/obmc-ikvm;branch=main;protocol=https"
SRCREV = "4e3d69b7d30eafffe58c9d4b2473f09ab8315c3d"

SYSTEMD_SERVICE:${PN} += "start-ipkvm.socket"

