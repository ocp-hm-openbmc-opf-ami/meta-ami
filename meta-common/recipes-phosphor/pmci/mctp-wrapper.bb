SUMMARY = "MCTP Wrapper Library"
DESCRIPTION = "Implementation of MCTP Wrapper Library"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=3b83ef96387f14655fc854ddc3c6bd57"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/mctp-wrapper.git;protocol=https;branch=main"
SRCREV = "d76409851b5cd36285f6b4480d53cb6d86df5dae"

S = "${UNPACKDIR}/git"

PV = "1.0+git${SRCPV}"

inherit cmake systemd

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEPENDS += " \
    libmctp-intel \
    systemd \
    sdbusplus \
    phosphor-logging \
    gtest \
    boost \
    phosphor-dbus-interfaces \
    "

SRC_URI:append = " file://0001-Fix-For-LF-Sync-Build-Failure.patch "

EXTRA_OECMAKE += "-DYOCTO_DEPENDENCIES=ON"
