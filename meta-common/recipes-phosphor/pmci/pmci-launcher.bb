SUMMARY = "PMCI Launcher"
DESCRIPTION = "Support to launch pmci services on-demand"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/pmci-launcher.git;protocol=https;branch=main"
SRCREV = "5f142da424b411e620507d03a3c3290ea2ecbfb9"

S = "${UNPACKDIR}/git"

PV = "1.0+git${SRCPV}"

inherit meson pkgconfig systemd

DEPENDS += " \
    systemd \
    sdbusplus \
    phosphor-logging \
    boost \
    i2c-tools \
    "

FILES:${PN} += "${systemd_system_unitdir}/xyz.openbmc_project.pmci-launcher.service"
SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.pmci-launcher.service"

FILES:${PN} += "${systemd_system_unitdir}/xyz.openbmc_project.I3C.Hub.Detector.service"
SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.I3C.Hub.Detector.service"
