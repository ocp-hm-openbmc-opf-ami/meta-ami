FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://nslcd.conf"

do_install:append() {
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/nslcd.conf ${D}${sysconfdir}/
}

