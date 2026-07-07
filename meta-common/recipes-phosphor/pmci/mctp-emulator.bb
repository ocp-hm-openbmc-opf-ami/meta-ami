SUMMARY = "MCTP Daemon"
DESCRIPTION = "Implementation of MCTP (DTMF DSP0236)"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=3b83ef96387f14655fc854ddc3c6bd57"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/mctp-emulator.git;protocol=https;branch=main"
SRCREV = "8e9571a34464344d4d116a449a2cb978d12accd1"

S = "${UNPACKDIR}/git"

PV = "1.0+git${SRCPV}"

inherit cmake pkgconfig systemd

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEPENDS += " \
    libmctp-intel \
    systemd \
    sdbusplus \
    phosphor-logging \
    boost \
    i2c-tools \
    cli11 \
    nlohmann-json \
    gtest \
    "

SRC_URI:append = " file://0001-Fix-For-LF-Sync.patch "

SYSTEMD_SERVICE:${PN} = "xyz.openbmc_project.mctp-emulator.service"
