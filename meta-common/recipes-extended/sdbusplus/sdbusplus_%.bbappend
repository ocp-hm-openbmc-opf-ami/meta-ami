FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/sdbusplus;branch=master;protocol=https"
#SRCREV = "4059635ff098987ffa04ec30017c9f1d7c83fd1b"
SRCREV = "1a39b64fafa18f03c62e5cbc6cd0d2da2cc6ed6d"
SRC_URI += " \
             file://0002-Skip-decoding-some-dbus-identifiers.patch \
           "
