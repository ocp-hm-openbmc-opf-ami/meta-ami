FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
RDEPENDS:${PN} += "bash"



SINGLE_SOL_SRC_URI:append:ast2700-default = "file://ast2700-sol-configure.sh "

SINGLE_SOL_SRC_URI = "file://sol-configure.sh \
		      file://single_sol_conf.ttyS2.conf \
		      file://001-stored-SOL-log-data-permanently.patch \
		     "

SRC_URI += "${@bb.utils.contains('MULTI_SOL_ENABLED', '1', ' ', SINGLE_SOL_SRC_URI , d)}"

do_install:append() {
if [ "${MULTI_SOL_ENABLED}" != "1" ]; then
    install -d ${D}${bindir}
    if [ "${MACHINE}" = "ast2700-default" ]; then
        install -m 0755 ${WORKDIR}/ast2700-sol-configure.sh ${D}${bindir}/sol-configure.sh
    else
        install -m 0755 ${WORKDIR}/sol-configure.sh ${D}${bindir}
        install -m 0644 ${WORKDIR}/single_sol_conf.ttyS2.conf ${D}/etc/obmc-console/server.ttyS2.conf
    fi
fi
}
