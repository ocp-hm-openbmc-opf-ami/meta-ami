SOL_PATH = "${@'${THISDIR}/${PN}/multi-sol' if d.getVar('MULTI_SOL_ENABLED') == '1' else '${THISDIR}/${PN}/single-sol'}"

FILESEXTRAPATHS:prepend := "${SOL_PATH}:"
RDEPENDS:${PN} += "bash"

Single_SOL_SRC_URI = "file://single_sol_conf.ttyS2.conf \
		      file://001-stored-SOL-log-data-permanently.patch \
		     "

Single_SOL_SRC_URI:append:ast2700-default = "file://ast2700-sol-configure.sh "
Single_SOL_SRC_URI:append:ast2700-dcscm = " file://ast2700-sol-configure.sh "

Single_SOL_SRC_URI:append:evb-ast2600 = "file://ast2600-sol-configure.sh "
Single_SOL_SRC_URI:append:intel-ast2600 = " file://ast2600-sol-configure.sh "

Multi_SOL_SRC_URI = " \
		file://multi_sol-configure.sh \
	"
SRC_URI += "${@bb.utils.contains('MULTI_SOL_ENABLED', '1', '${Multi_SOL_SRC_URI}', '${Single_SOL_SRC_URI}' , d)}"

do_install:append() {
    install -d ${D}${bindir}
if [ "${MULTI_SOL_ENABLED}" = "1" ]; then
    install -m 0755 ${WORKDIR}/multi_sol-configure.sh ${D}${bindir}/sol-configure.sh
else

    if [ "${MACHINE}" = "evb-ast2600" ] || [ "${MACHINE}" = "intel-ast2600" ]; then
	install -m 0755 ${WORKDIR}/ast2600-sol-configure.sh ${D}${bindir}/sol-configure.sh
    elif [ "${MACHINE}" = "ast2700-default" ] || [ "${MACHINE}" = "ast2700-dcscm" ]; then
	install -m 0755 ${WORKDIR}/ast2700-sol-configure.sh ${D}${bindir}/sol-configure.sh
    fi

    install -m 0644 ${WORKDIR}/single_sol_conf.ttyS2.conf ${D}/etc/obmc-console/server.ttyS2.conf
fi
}
