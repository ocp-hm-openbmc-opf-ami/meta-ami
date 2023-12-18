FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
RDEPENDS:${PN} += "bash"

SINGLE_SOL_SRC_URI = "file://sol-configure.sh \
		      file://server.ttyS2.conf \
		      file://001-stored-SOL-log-data-permanently.patch \
		     "

SRC_URI += "${@bb.utils.contains('MULTI_SOL_ENABLED', '1', ' ', SINGLE_SOL_SRC_URI , d)}"

do_install:append() {
if [ "${MULTI_SOL_ENABLED}" != "1" ]; then
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/sol-configure.sh ${D}${bindir}
fi
}
