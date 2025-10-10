# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/ipmbbridge.git;branch=master;protocol=https"
SRCREV = "0afdd8cc08adb5a5657766cc259fb7e98a0d807f"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += " \
           file://0002-Add-log-count-limitation-to-requestAdd.patch \
           file://ipmb-channels.json \
           file://0001-Add-dbus-method-SlotIpmbRequest.patch \
           file://0003-Fix-for-clearing-outstanding-requests.patch \
           file://0004-Support-unique-i2c-address-to-BMC.patch \
           "

do_install:append() {
    install -D ${WORKDIR}/ipmb-channels.json \
               ${D}/usr/share/ipmbbridge
}
