SUMMARY = "AMI Session Management Backend implementation"
DESCRIPTION = "Session Management application"
LICENSE = "CLOSED"


SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/session-manager.git;protocol=https;branch=main"
SRCREV = "d61120667173d069c6dfc0e057023037a862a2e0"

CXXFLAGS:append = " -Wno-missing-field-initializers"

S = "${UNPACKDIR}/git"
PV = "1.0+git${SRCPV}"

inherit pkgconfig meson systemd
inherit obmc-phosphor-systemd

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.SessionManager.service"
SYSTEMD_SERVICE:${PN} += "dropbear-session-manager.service"

DEPENDS += " \
    boost \
    sdbusplus \
    phosphor-dbus-interfaces \
    phosphor-logging \
    systemd \
    "


FILES:${PN}  += "${systemd_system_unitdir}/xyz.openbmc_project.SessionManager.service"
FILES:${PN}  += "${systemd_system_unitdir}/dropbear-session-manager.service"
