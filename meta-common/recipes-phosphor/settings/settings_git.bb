SUMMARY = "Settings"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/settings-manager.git;protocol=https;branch=main"
SRCREV = "c4c2218f49ee04ca5c902f5d8df39505cc02329a"
PV = "0.1+git${SRCPV}"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"


SYSTEMD_SERVICE:${PN} = "xyz.openbmc_project.Settings.service"

DEPENDS = "boost \
           nlohmann-json \
           sdbusplus"

S = "${UNPACKDIR}/git"
inherit cmake pkgconfig systemd

EXTRA_OECMAKE = "-DYOCTO=1"

