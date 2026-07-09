SUMMARY = "KVM dbus interface and monitor service"
DESCRIPTION = "Service providing dbus interface and monitoring for KVM"
LICENSE = "CLOSED"
DEPENDS = "systemd nlohmann-json sdbusplus phosphor-logging phosphor-dbus-interfaces"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/obmc-ikvm;protocol=https;branch=main"

# Use AUTOREV to get the latest revision from the repository
SRCREV = "4250fc1f0a6881516f09d8af7864c937590dcda3"
#SRCREV = "${AUTOREV}"

# Set the source directory
S = "${WORKDIR}/git/kvm-dbus-monitor"
PV = "1.0+git${SRCPV}"

inherit pkgconfig meson systemd
inherit obmc-phosphor-systemd

SYSTEMD_SERVICE:${PN} += "kvm-dbus-monitor.service"

FILES:${PN} += "${systemd_system_unitdir}/auto-video-trigger.timer \
                ${systemd_system_unitdir}/auto-video-trigger.service"

SYSTEMD_SERVICE:${PN} += "auto-video-trigger.timer"

