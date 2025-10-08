SUMMARY = "Provision mode daemon - RestrictionMode"
DESCRIPTION = "Daemon allows to configure RestrictionMode property"

PV = "1.0+git${SRCPV}"

S = "${WORKDIR}/git"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"


SRC_URI = "git://git@github.com/intel-bmc/firmware.bmc.openbmc.applications.provisioning-mode-manager.git;protocol=ssh;branch=main"

SRCREV = "723c121a91fd9277b03bff8c0aa6aa85e727fd40"

inherit cmake systemd pkgconfig
SYSTEMD_SERVICE:${PN} = "xyz.openbmc_project.RestrictionMode.Manager.service"

DEPENDS = "boost sdbusplus phosphor-logging"
