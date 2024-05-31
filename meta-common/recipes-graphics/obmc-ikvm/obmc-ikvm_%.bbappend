FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/obmc-ikvm;branch=main;protocol=https"
SRCREV = "3b9ce058b5d003fdb142db25b5e0f081c4be84bc"

SYSTEMD_SERVICE:${PN} += "start-ipkvm.socket"

