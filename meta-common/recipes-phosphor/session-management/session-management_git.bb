SUMMARY = "Session Management Backend implementation"
DESCRIPTION = "Session Management application"
LICENSE = "CLOSED"

SRC_URI = " \
           file://session_management.cpp \ 
           file://session_management.hpp \ 
           file://meson.build \
           file://xyz.openbmc_project.SessionManager.service \
          "

S = "${WORKDIR}"

inherit pkgconfig meson systemd
inherit obmc-phosphor-systemd

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.SessionManager.service"

DEPENDS += " \
    boost \
    sdbusplus \
    phosphor-dbus-interfaces \
    phosphor-logging \
    systemd \
    "


FILES:${PN}  += "${systemd_system_unitdir}/xyz.openbmc_project.SessionManager.service"
