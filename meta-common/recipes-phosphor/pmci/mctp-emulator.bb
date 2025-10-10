SUMMARY = "MCTP Daemon"
DESCRIPTION = "Implementation of MCTP (DTMF DSP0236)"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=bcd9ada3a943f58551867d72893cc9ab"

SRC_URI = "git://git@github.com/intel-collab/firmware.bmc.openbmc.applications.mctp-emulator.git;protocol=ssh;branch=main"
SRCREV = "61ca6f9a45d06d2822728a34aac36e0bd9047299"

S = "${WORKDIR}/git"

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

SYSTEMD_SERVICE:${PN} = "xyz.openbmc_project.mctp-emulator.service"
