SUMMARY = "PEF and alert management application"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/platform-event-filter.git;protocol=https;branch=main"


SRCREV = "82aec032bbb6792a876d0efcdad62a502b203eef"

SRC_URI += "file://pef-alert-manager.json \
            file://pef-lan-param-config.json \
           "

S = "${WORKDIR}/git"
PV = "1.0+git${SRCPV}"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit cmake systemd pkgconfig

EXTRA_OECMAKE:append = "${@' -DSTATIC_SENSOR_NUMBER_ENABLE=ON' if d.getVar('STATIC_SENSOR_NUMBER_ENABLE') == '1' else ' -DSTATIC_SENSOR_NUMBER_ENABLE=OFF'}"

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
    install -m 0644 ${UNPACKDIR}/pef-alert-manager.json ${D}/var/lib/pef-alert-manager
    install -m 0644 ${UNPACKDIR}/pef-lan-param-config.json ${D}/var/lib/pef-alert-manager
}
