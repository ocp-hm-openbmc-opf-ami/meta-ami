FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/obmc-ikvm;branch=main;protocol=https"
SRCREV = "71e0c6a7719b7bed22f69c0b7a2a25c8f52928fc"

SYSTEMD_SERVICE:${PN} += "start-ipkvm.socket"

