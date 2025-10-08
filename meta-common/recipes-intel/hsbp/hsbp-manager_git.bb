SUMMARY = "HSBP Manager"
DESCRIPTION = "HSBP Manager monitors HSBPs through SMBUS"

SRC_URI = "git://github.com/openbmc/s2600wf-misc.git;branch=master;protocol=https"
SRCREV = "a2c6e1d04dd82834ae002237bfef3cc52ab47138"
PV = "0.1+git${SRCPV}"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://0001-Fix-Build-issue-downstream.patch \
    file://0002-Default-to-enable-all-clock-outputs.patch \
    "

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SYSTEMD_SERVICE:${PN} = "hsbp-manager.service"

DEPENDS = "boost \
           i2c-tools \
           sdbusplus \
           libgpiod"

S = "${WORKDIR}/git/hsbp-manager"
inherit cmake pkgconfig systemd

EXTRA_OECMAKE = "-DYOCTO=1"

