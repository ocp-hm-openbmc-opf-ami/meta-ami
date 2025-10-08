SUMMARY = "MCTP Daemon"
DESCRIPTION = "Implementation of MCTP (DTMF DSP0236)"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

SRC_URI = "git://git@github.com/intel-bmc/firmware.bmc.openbmc.applications.mctpd.git;protocol=ssh;branch=main"
#SRCREV = "d1cba25824ed0b7b11d25aedb63fd81240c132e9"
SRCREV = "aa25b313ea3358104c5836b0d1e2c240aada59fb"

S = "${WORKDIR}/git"

PV = "1.0+git${SRCPV}"

OECMAKE_SOURCEPATH = "${S}"

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
    phosphor-dbus-interfaces \
    udev \
    "
FILES:${PN} += "${systemd_system_unitdir}/xyz.openbmc_project.mctpd@.service"
FILES:${PN} += "/usr/share/mctp/mctp_config.json"
