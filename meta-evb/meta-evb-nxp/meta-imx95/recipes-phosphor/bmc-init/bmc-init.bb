SUMMARY = "BMC initialization for i.MX93"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit allarch systemd

SYSTEMD_SERVICE:${PN} = "bmc-state-change.service bmc-console.service"
SYSTEMD_AUTO_ENABLE = "enable"

SRC_URI = " \
    file://bmc-state-change.service \
    file://bmc-console.service \
"

S = "${UNPACKDIR}"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/bmc-state-change.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${UNPACKDIR}/bmc-console.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} += "${systemd_system_unitdir}/*"

RDEPENDS:${PN} += "libgpiod-tools phosphor-state-manager"
