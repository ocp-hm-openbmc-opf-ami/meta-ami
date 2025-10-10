SUMMARY = "SPDM Responder Stack"
DESCRIPTION = "Implementation of SPDM specifications"

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta-core/meta/files/common-licenses/Intel-BMC-FWSEC;md5=8ad5886152d8fa09daa41fbe51fff047"

inherit systemd
inherit pkgconfig meson

DEPENDS += " \
            systemd boost spdmapplib\
            "

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/firmware.bmc.openbmc.applications.spdmd.git;protocol=https;branch=main"
SRCREV = "ae03c0c003e8806aefe055a5bbf4d5f37ad87264"

S = "${WORKDIR}/git"
PV = "1.0+git${SRCPV}"

SYSTEMD_SERVICE:${PN} = "xyz.openbmc_project.spdmd.service"

