FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI += " \
           file://krb5.conf \
           file://krb5.keytab \
           "

do_install:append() {
    install -d ${D}${sysconfdir}
    install -m 0755 ${WORKDIR}/krb5.conf ${D}/${sysconfdir}/krb5.conf
    install -m 0755 ${WORKDIR}/krb5.keytab ${D}/${sysconfdir}/krb5.keytab
}

FILES:${PN}:append = " ${sysconfdir}/*"
