SUMMARY = "MCTP Daemon"
DESCRIPTION = "Implementation of MCTP (DTMF DSP0236)"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/mctpd.git;protocol=https;branch=main"
SRCREV = "d104dfa8e4d4c1651a2fe98c06df89bfe011630f"

S = "${UNPACKDIR}/git"

PV = "1.0+git${SRCPV}"

OECMAKE_SOURCEPATH = "${S}"

inherit meson pkgconfig systemd

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

RDEPENDS:${PN} += "rsyslog"

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
    libspdm \
    "

EXTRA_OEMESON = "-Dyocto_dep='enabled'"

CXXFLAGS:append = " -Wno-error=null-dereference"

FILES:${PN} += "${systemd_system_unitdir}/xyz.openbmc_project.mctpd@.service"
FILES:${PN} += "/usr/share/mctp/mctp_config.json"
