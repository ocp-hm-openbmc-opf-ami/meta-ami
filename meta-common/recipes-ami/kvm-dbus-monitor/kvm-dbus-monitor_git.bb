SUMMARY = "KVM dbus interface and monitor service"
DESCRIPTION = "Service providing dbus interface and monitoring for KVM"
LICENSE = "CLOSED"
DEPENDS = "systemd nlohmann-json sdbusplus phosphor-logging phosphor-dbus-interfaces"

#SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/obmc-ikvm;protocol=https;branch=main"
SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/obmc-ikvm;protocol=https;branch=feature/auto-video-settings-support"

# Use AUTOREV to get the latest revision from the repository
SRCREV = "76c545c6051de06180d79654abe2c7e70ef87acb"
#SRCREV= "<COMMIT SHA>"

# Set the source directory
S = "${WORKDIR}/git/kvm-dbus-monitor"
PV = "1.0+git${SRCPV}"

inherit pkgconfig meson systemd
inherit obmc-phosphor-systemd

SYSTEMD_SERVICE:${PN} += "kvm-dbus-monitor.service"

FILES:${PN} += "${systemd_system_unitdir}/auto-video-trigger.timer \
                ${systemd_system_unitdir}/auto-video-trigger.service"

SYSTEMD_SERVICE:${PN} += "auto-video-trigger.timer"

