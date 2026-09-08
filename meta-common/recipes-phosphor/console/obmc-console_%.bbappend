SOL_PATH = "${@'${THISDIR}/${PN}/multi-sol' if d.getVar('MULTI_SOL_ENABLED') == '1' else '${THISDIR}/${PN}/single-sol'}"

FILESEXTRAPATHS:prepend := "${SOL_PATH}:"
RDEPENDS:${PN} += "bash"

SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/obmc-console.git;branch=integrate-onetree-3.1.1;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "3d271b52351a344064ca03a91aa2136b1ea7b6e0"

Single_SOL_SRC_URI = "file://single_sol_conf.ttyS2.conf \
		     "

Single_SOL_SRC_URI:append:ast2700-default = "file://ast2700-sol-configure.sh "
Single_SOL_SRC_URI:append:ast2700-dcscm = " file://ast2700-sol-configure.sh "
Single_SOL_SRC_URI:append:ast2700-a0-dcscm = " file://ast2700-sol-configure.sh "

Single_SOL_SRC_URI:append:evb-ast2600 = "file://ast2600-sol-configure.sh "
Single_SOL_SRC_URI:append:intel-ast2600 = " file://ast2600-sol-configure.sh "


Multi_SOL_SRC_URI = " \
		file://multi_sol-configure.sh \
	"
SRC_URI += "${@bb.utils.contains('MULTI_SOL_ENABLED', '1', '${Multi_SOL_SRC_URI}', '${Single_SOL_SRC_URI}' , d)}"

PACKAGECONFIG[obmc-console-log] = "-Dobmc-console-log=true,-Dobmc-console-log=false"

do_install:append() {
    install -d ${D}${bindir}
if [ "${MULTI_SOL_ENABLED}" = "1" ]; then
    install -m 0755 ${UNPACKDIR}/multi_sol-configure.sh ${D}${bindir}/sol-configure.sh
else

    if [ "${MACHINE}" = "evb-ast2600" ] || [ "${MACHINE}" = "intel-ast2600" ]; then
	install -m 0755 ${UNPACKDIR}/ast2600-sol-configure.sh ${D}${bindir}/sol-configure.sh
    elif [ "${MACHINE}" = "ast2700-default" ] || [ "${MACHINE}" = "ast2700-dcscm" ] || [ "${MACHINE}" = "ast2700-a0-dcscm" ]; then
	install -m 0755 ${UNPACKDIR}/ast2700-sol-configure.sh ${D}${bindir}/sol-configure.sh
    fi

    install -m 0644 ${UNPACKDIR}/single_sol_conf.ttyS2.conf ${D}/etc/obmc-console/server.ttyS2.conf
fi
}
