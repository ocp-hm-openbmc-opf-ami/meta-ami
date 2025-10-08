SUMMARY = "AC Boot Check"
DESCRIPTION = "Script to check the resetreason for AC boot"

S = "${WORKDIR}"
SRC_URI = "file://ac-boot-check.sh \
           file://ac-boot-check.service \
"

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta-core/meta/files/common-licenses/Intel-BMC-Base;md5=f66be55877b5b739110e445efdcf5fbc"
RDEPENDS:${PN} += "bash"

inherit systemd

FILES:${PN} += "${systemd_system_unitdir}/ac-boot-check.service"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/ac-boot-check.service ${D}${systemd_system_unitdir}
    install -d ${D}${bindir}
    install -m 0755 ${S}/ac-boot-check.sh ${D}/${bindir}/ac-boot-check.sh
}

SYSTEMD_SERVICE:${PN} += " ac-boot-check.service"
