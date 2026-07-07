SUMMARY = "HSBP Manager"
DESCRIPTION = "HSBP Manager monitors HSBPs through SMBUS"

SRC_URI = "git://github.com/openbmc/s2600wf-misc.git;branch=master;protocol=https"
SRCREV = "ed4c97df285cf38def98919ff9ede05586468685"
PV = "0.1+git${SRCPV}"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://0001-Fix-Build-issue-downstream.patch \
    "

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SYSTEMD_SERVICE:${PN} = "hsbp-manager.service"

DEPENDS = "boost \
           i2c-tools \
           sdbusplus \
           libgpiod"

S = "${UNPACKDIR}/git/hsbp-manager"
inherit meson pkgconfig systemd

EXTRA_OECMAKE = "-DYOCTO=1"

