FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://mctp-init.sh \
    "

RDEPENDS:${PN} = " bash "

do_install:append() {
    install -m 0755 ${WORKDIR}/mctp-init.sh ${D}${bindir}
}
