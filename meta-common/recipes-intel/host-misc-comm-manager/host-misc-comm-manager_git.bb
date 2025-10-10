SUMMARY = "Miscellaneous host interface communication manager"
DESCRIPTION = "Daemon exposes Miscellaneous host interface communications like \
               platform reset, mail box & scratch pad"

PV = "1.0+git${SRCPV}"

S = "${WORKDIR}/git"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "git://git@github.com/intel-bmc/firmware.bmc.openbmc.applications.host-misc-comm-manager;protocol=ssh;branch=main"

SRCREV = "cf4628455d288fca944f84996e58422b9e806dc2"

inherit cmake systemd pkgconfig
SYSTEMD_SERVICE:${PN} = "xyz.openbmc_project.Host.Misc.Manager.service"

DEPENDS = "boost sdbusplus phosphor-logging libgpiod"
