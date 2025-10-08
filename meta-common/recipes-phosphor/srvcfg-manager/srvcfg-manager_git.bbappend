FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# The URI is required for the autobump script but keep it commented
# to not override the upstream value
#SRC_URI = "git://github.com/openbmc/service-config-manager;branch=master;protocol=https"
SRCREV = "70c78fe409453a0590d0a93f0a0503d6c30d5118"

# Telemetry Features:
SRC_URI += " \
            file://telemetry/0001-Added-PmtService-to-Service-Config-Manager.patch \
"
