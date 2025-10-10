FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI  = "git://github.com/openbmc/host-error-monitor;branch=master;protocol=https"
SRCREV = "58fa67cb3c299c3c3d82e847ecd109655043c279"
inherit pkgconfig
PACKAGECONFIG[send-to-logger] =""
# PACKAGECONFIG:remove += "send-to-logger"
EXTRA_OECMAKE = "-DYOCTO=1 -DLIBPECI=1 -DCRASHDUMP=1"

# RAS Offload features:
SRC_URI += " \
    file://ras-offload/0001-Add-ERR0-monitor-for-RAS.patch \
    "
