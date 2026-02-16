FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "995ebe7ef29c9890e87aa4c0e6772f7a586146da"

SRC_URI += " \
             file://0001-Recreate-Fix-for-EventLog-Not-Generated-in-Redfish.patch \
             file://0002-Fix-for-coverity-issues-in-telemetry.patch \
           "


