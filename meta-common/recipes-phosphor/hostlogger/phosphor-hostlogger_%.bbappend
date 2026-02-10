SOL_PATH = "${@'${THISDIR}/${PN}/multi-sol' if d.getVar('MULTI_SOL_ENABLED') == '1' else '${THISDIR}/${PN}/single-sol'}"

FILESEXTRAPATHS:prepend := "${SOL_PATH}:"

SRCREV = "531629353c56b8cc78610081c430d5250e34b3c1"

SINGLE_SOL_SRC_URI = " \
	file://ttyS2.conf \
	"

MULTI_SOL_SRC_URI = " \
	file://ttyS0.conf \
	file://ttyS1.conf \
	file://ttyS2.conf \
	file://ttyS8.conf \
	"
SRC_URI += "${@bb.utils.contains('MULTI_SOL_ENABLED', '1', '${MULTI_SOL_SRC_URI}', '${SINGLE_SOL_SRC_URI}' , d)}"

SRC_URI += "\
        file://0001-Fix-for-OT-coverity-issue.patch \
           "

do_install:append() {
    install -m 0755 -d ${D}${sysconfdir}/${BPN}
if [ "${MULTI_SOL_ENABLED}" = "1" ]; then
    install -m 0644 ${WORKDIR}/ttyS*.conf ${D}${sysconfdir}/${BPN}/
else
    install -m 0644 ${WORKDIR}/ttyS2.conf ${D}${sysconfdir}/${BPN}/
fi

          # Remove upstream-provided default configuration
          rm -f ${D}${sysconfdir}/${BPN}/ttyVUART0.conf
}
