FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/obmc-ikvm;branch=main;protocol=https"
SRCREV = "4a5113e1b3dcf2a460ffc865e041c207f47d54e9"

SYSTEMD_SERVICE:${PN} += "start-ipkvm.socket"

