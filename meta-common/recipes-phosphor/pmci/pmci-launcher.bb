SUMMARY = "PMCI Launcher"
DESCRIPTION = "Support to launch pmci services on-demand"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

SRC_URI = "git://git@github.com/intel-bmc/firmware.bmc.openbmc.applications.pmci-launcher.git;protocol=ssh;branch=main"
SRCREV = "0522aef10be7300d92789535f1a9e45164032d6a"

S = "${WORKDIR}/git"

PV = "1.0+git${SRCPV}"

inherit cmake pkgconfig systemd

DEPENDS += " \
    systemd \
    sdbusplus \
    phosphor-logging \
    boost \
    "
FILES:${PN} += "${systemd_system_unitdir}/xyz.openbmc_project.pmci-launcher.service"
SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.pmci-launcher.service"
