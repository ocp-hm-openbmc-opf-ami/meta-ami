FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
             file://mac-check \
           "

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/mac-check  ${D}${bindir}
}

