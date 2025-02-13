SRCREV = "3995a361af50f6708090bf853494cf1659864cd4"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
             file://0001-Fix-for-EventLog-Not-Generated-in-Redfish.patch \
           "


