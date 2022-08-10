SRCREV = "95f69336c0b236eb3b9c878173aa4b375171d48e"

inherit pkgconfig

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += " \
           file://dcmi_whitelists_conf.patch \
           "
