FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/obmc-ikvm;branch=main;protocol=https"
SRCREV = "720b996278ab27764f6c93fdc4238661b7a824a7"

SYSTEMD_SERVICE:${PN} += "start-ipkvm.socket"

