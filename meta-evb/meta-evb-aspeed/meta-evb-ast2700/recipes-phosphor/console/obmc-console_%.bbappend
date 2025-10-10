# Sync to the latest obmc-console. We can remove it after rebasing OpenBMC.
SRCREV = "366651d9ef0e03f97b1e1d2b6188f2b452044d1c"

DEPENDS += "iniparser \
            libgpiod \
           "
EXTRA_OEMESON = "-Dtests=false"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-config-enhance-aspeed-uart-routing-for-dual-nodes.patch"

