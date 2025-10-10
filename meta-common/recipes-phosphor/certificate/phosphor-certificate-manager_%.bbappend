# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/phosphor-certificate-manager;branch=master;protocol=https"
SRCREV = "8dbcc72d55f007c43c504ee98e40f352e996426f"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://0001-Add-certificate-key-length-check.patch \
    "

EXTRA_OEMESON += " -Dallow-expired=disabled"
