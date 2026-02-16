SUMMARY = "Security registers check"
DESCRIPTION = "script tool to check if registers value are security \
               log the security event to systemd journal, and also log to redfish \
              "

S = "${WORKDIR}"
SRC_URI = "file://security-registers-check.sh \
           file://security-registers-check.service \
"

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta-core/meta/files/common-licenses/Intel-BMC-Base;md5=f66be55877b5b739110e445efdcf5fbc"
RDEPENDS:${PN} += "bash logger-systemd"

inherit systemd

FILES:${PN} += "${systemd_system_unitdir}/security-registers-check.service"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/security-registers-check.service ${D}${systemd_system_unitdir}
    install -d ${D}${bindir}
    install -m 0755 ${S}/security-registers-check.sh ${D}/${bindir}/security-registers-check.sh
}

SYSTEMD_SERVICE:${PN} += " security-registers-check.service"
