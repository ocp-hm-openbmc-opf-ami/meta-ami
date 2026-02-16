# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/telemetry.git;branch=master;protocol=https"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON += " -Dmax-reports=10"
EXTRA_OEMESON += " -Dmax-reading-parameters=200"
EXTRA_OEMESON += " -Dmin-interval=1000"
EXTRA_OEMESON += " -Dservice-wants="['nv-sync.service']""
EXTRA_OEMESON += " -Dservice-after="['nv-sync.service']""

