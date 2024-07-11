FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/obmc-ikvm;branch=main;protocol=https"
SRCREV = "cc3a3cd3f471194af43fa4b48c39538703549a71"

SYSTEMD_SERVICE:${PN} += "start-ipkvm.socket"

