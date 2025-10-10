# Enable downstream autobump
# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/x86-power-control.git;branch=master;protocol=https"
SRCREV = "b1e34a11f5c64a7c4225fb4cf15ee7f9368cbef4"

FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += " \
        file://0001-Extend-VR-Watchdog-timeout.patch \
        "
