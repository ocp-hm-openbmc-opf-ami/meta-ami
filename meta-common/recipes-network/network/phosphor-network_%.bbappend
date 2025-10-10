FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEPENDS += "nlohmann-json boost"

# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/phosphor-networkd;branch=master;protocol=https"
SRCREV = "91f60564228f4546cbe1c2bee3c760a651d8fae0"

EXTRA_OEMESON:append = " -Ddefault-ipv6-accept-ra=true"
EXTRA_OEMESON:append = " -Dhyp-nw-config=false"
EXTRA_OEMESON:append = " -Dpersist-mac=false"
