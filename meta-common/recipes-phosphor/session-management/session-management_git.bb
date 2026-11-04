SUMMARY = "AMI Session Management Backend implementation"
DESCRIPTION = "Session Management application"
LICENSE = "CLOSED"


SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/session-manager.git;protocol=https;branch=main"
SRCREV = "adaf066b628295eaef5026040aed850351f5c3e9"

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
