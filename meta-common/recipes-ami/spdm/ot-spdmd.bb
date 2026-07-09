SUMMARY = "SPDM Responder Stack"
DESCRIPTION = "Implementation of SPDM specifications"

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=65a69a674f34a9f30737c9f0abd4fc5c"

inherit systemd
inherit pkgconfig meson

DEPENDS += " \
            systemd boost ot-spdmapplib \
            phosphor-logging \
            phosphor-dbus-interfaces \
            sdeventplus \
            nlohmann-json \
            cli11 \
        "

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/ot-spdmd.git;protocol=https;branch=main"
SRCREV = "9ce6f9a969a18e6a7d085142750f42fbe34abcf4"

S = "${WORKDIR}/git"
PV = "1.0+git${SRCPV}"

SYSTEMD_SERVICE:${PN} = "xyz.openbmc_project.spdmd.service"
FILES:${PN} += " \
   usr \
"

EXTRA_OEMESON += " \
  -Dfetch_serialnumber_from_responder=26 \
"
EXTRA_OEMESON:append = "${@bb.utils.contains('ENABLE_COMMUNITY_MCTP_KERNEL_MODE', '1', ' -Dcommunity_mctp=true', ' -Dcommunity_mctp=false', d)}"
