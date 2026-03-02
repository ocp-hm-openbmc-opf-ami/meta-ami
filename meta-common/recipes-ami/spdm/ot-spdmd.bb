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

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/ot-spdmd.git;protocol=https;branch=main"
SRCREV = "eaac7dbcdd2580f8c8de5b57dc44dd53d5d757c8"

S = "${WORKDIR}/git"
PV = "1.0+git${SRCPV}"

SYSTEMD_SERVICE:${PN} = "xyz.openbmc_project.spdmd.service"
FILES:${PN} += " \
   usr \
"

EXTRA_OEMESON += " \
  -Dfetch_serialnumber_from_responder=26 \
"

