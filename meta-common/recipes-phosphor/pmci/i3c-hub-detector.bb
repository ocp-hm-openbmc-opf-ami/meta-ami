SUMMARY = "I3C Hub Detector"
DESCRIPTION = "Service to detect I3C and I2C devices on BMC"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

SRC_URI = "git://git@git.ami.com/core/ami-bmc/one-tree/intel/firmware.bmc.openbmc.applications.i3c-hub-detector.git;protocol=ssh;branch=oks-main"
SRCREV = "a2ff2a01ff1a249232dcc00956ddf9c4dc03611d"

S = "${UNPACKDIR}/git"

PV = "1.0+git${SRCPV}"

inherit meson pkgconfig systemd

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEPENDS += " \
    systemd \
    sdbusplus \
    phosphor-logging \
    boost \
    i2c-tools \
    "

SYSTEMD_SERVICE:${PN} = "com.intel.i3c-hub-detector.service"
EXTRA_OEMESON = "-Dtests=disabled"
FILES:${PN} += "${systemd_system_unitdir}/com.intel.i3c-hub-detector.service"
