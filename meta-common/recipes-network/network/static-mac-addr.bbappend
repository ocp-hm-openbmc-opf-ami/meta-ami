FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
             file://mac-check \
	     file://static-mac-addr.service \
           "

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/mac-check  ${D}${bindir}
}

