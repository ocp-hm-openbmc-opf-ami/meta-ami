# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/peci-pcie;branch=master;protocol=https"
SRCREV = "f0f39a9d0b017181efae5b9567623ee53357f51e"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://0001-Skip-SPR-CPU-buses.patch \
    "

EXTRA_OECMAKE += "-DWAIT_FOR_OS_STANDBY=1 -DUSE_RDENDPOINTCFG=1"
