SUMMARY = "AMI Session Management Backend implementation"
DESCRIPTION = "Session Management application"
LICENSE = "CLOSED"


SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/session-manager.git;protocol=https;branch=main"
SRCREV = "249eced4f19939fbdfeca5a535cd689f81b7ef71"

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
