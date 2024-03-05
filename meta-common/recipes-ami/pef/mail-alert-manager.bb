SUMMARY = "mail alert management application"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/email-alert-manager.git;protocol=https;branch=main"
SRCREV = "5cf01cc6de4453b1bb20201806e20e2336c39dde"

SRC_URI += " \
	    file://primary_smtp_config.json \
	    file://secondary_smtp_config.json \
           "

S = "${WORKDIR}/git"
PV = "1.0+git${SRCPV}"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit cmake systemd pkgconfig

DEPENDS += " \
    sdbusplus \
    boost \
    nlohmann-json \
    phosphor-logging \
    libesmtp \
    "

FILES:${PN} += "${systemd_system_unitdir}/mail-alert-manager.service"
SYSTEMD_SERVICE:${PN} = "mail-alert-manager.service"

do_install:append() {
    install -d ${D}/var/lib/alert
    install -m 0644 ${WORKDIR}/primary_smtp_config.json ${D}/var/lib/alert
    install -m 0644 ${WORKDIR}/secondary_smtp_config.json ${D}/var/lib/alert
}
