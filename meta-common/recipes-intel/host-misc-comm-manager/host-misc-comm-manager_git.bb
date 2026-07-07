SUMMARY = "Miscellaneous host interface communication manager"
DESCRIPTION = "Daemon exposes Miscellaneous host interface communications like \
               platform reset, mail box & scratch pad"

PV = "1.0+git${SRCPV}"

S = "${UNPACKDIR}/git"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/host-misc-comm-manager.git;protocol=https;branch=main"

SRCREV = "0fc4b83e3ec932708a315459315ae8c00192ca46"

inherit cmake systemd pkgconfig
SYSTEMD_SERVICE:${PN} = "xyz.openbmc_project.Host.Misc.Manager.service"

DEPENDS = "boost sdbusplus phosphor-logging libgpiod"
