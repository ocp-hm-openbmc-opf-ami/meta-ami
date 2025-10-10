# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/telemetry.git;branch=master;protocol=https"
SRCREV = "3995a361af50f6708090bf853494cf1659864cd4"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Temporary downstream mirror of upstream patch
SRC_URI += " \
             file://0002-Shorten-threshold-name-in-RedFish-log-message.patch \
           "

EXTRA_OEMESON += " -Dmax-reports=10"
EXTRA_OEMESON += " -Dmax-reading-parameters=200"
EXTRA_OEMESON += " -Dmin-interval=1000"
EXTRA_OEMESON += " -Dservice-wants="['nv-sync.service']""
EXTRA_OEMESON += " -Dservice-after="['nv-sync.service']""

