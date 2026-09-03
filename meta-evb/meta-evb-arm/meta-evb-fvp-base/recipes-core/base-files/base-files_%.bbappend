FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://fstab \
"

do_install:append() {
    install -D -m 644 ${UNPACKDIR}/fstab ${D}/${sysconfdir}/fstab
}
