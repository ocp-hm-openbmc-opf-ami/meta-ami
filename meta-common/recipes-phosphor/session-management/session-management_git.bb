SUMMARY = "AMI Session Management Backend implementation"
DESCRIPTION = "Session Management application"
LICENSE = "CLOSED"

SRC_URI = " \
           file://session_management.cpp \ 
           file://session_management.hpp \ 
           file://meson.build \
           file://xyz.openbmc_project.SessionManager.service \
           file://dropbear_manager.cpp \
           file://dropbear-session-manager.service \
          "

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
