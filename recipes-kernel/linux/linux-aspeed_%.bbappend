FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://0001-Fix-virtual-USB-hub-not-working-for-evb-ast2600.patch \
    "
