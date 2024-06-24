FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/obmc-ikvm;branch=main;protocol=https"
SRCREV = "75214b3e227b238ce52f9c8173787493322b1ba1"

SYSTEMD_SERVICE:${PN} += "start-ipkvm.socket"

