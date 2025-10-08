FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

# Use the latest to support obmc-ikvm properly
# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/LibVNC/libvncserver;branch=master;protocol=https"
SRCREV = "8560a5a72d76fc3ab3484ca41f604116807f34e8"
