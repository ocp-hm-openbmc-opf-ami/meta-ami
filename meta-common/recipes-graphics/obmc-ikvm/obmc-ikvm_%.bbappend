FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/obmc-ikvm;branch=main;protocol=https"
SRCREV = "6ab0906a54c97ccc5efe0fa6d24defbfee88683f"

SYSTEMD_SERVICE:${PN} += "start-ipkvm.socket"

