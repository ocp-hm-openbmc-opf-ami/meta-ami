FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/obmc-ikvm;branch=master;protocol=https"
# Todo: Commented out the patch to avoid build failure
#SRCREV = "12b2380a6b7efb8b2d33ea33e12e5870f19988ed"
