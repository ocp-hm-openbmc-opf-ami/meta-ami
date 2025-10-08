SUMMARY = "PEF and alert management application"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/platform-event-filter.git;protocol=https;branch=main"


SRCREV = "31c69e162005ecedbe4c79c2d2d227f19c103a45"

SRC_URI += "file://pef-alert-manager.json \
            file://pef-lan-param-config.json \
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
    phosphor-snmp \
    "

FILES:${PN} += "${systemd_system_unitdir}/pef-configuration.service \
                ${systemd_system_unitdir}/pef-event-filtering.service"
SYSTEMD_SERVICE:${PN} = "pef-configuration.service \
                         pef-event-filtering.service"

do_install:append() {
    install -d ${D}/var/lib/pef-alert-manager
    install -m 0644 ${WORKDIR}/pef-alert-manager.json ${D}/var/lib/pef-alert-manager
    install -m 0644 ${WORKDIR}/pef-lan-param-config.json ${D}/var/lib/pef-alert-manager
}
