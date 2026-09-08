SUMMARY = "SNMP Agent Daemon"
DESCRIPTION = "Daemon snmp-agent"
LICENSE = "CLOSED"

PV = "1.0+git"

inherit meson pkgconfig
inherit obmc-phosphor-dbus-service

DEPENDS += "phosphor-logging"
DEPENDS += "phosphor-snmp"
DEPENDS += "systemd"
DEPENDS += "boost"
DEPENDS += "sdbusplus"
DEPENDS += "sdeventplus"
DEPENDS += "phosphor-dbus-interfaces"
DEPENDS += "net-snmp"


SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/snmp-agent;protocol=https;branch=integrate-onetree-3.1.1"
SRC_URI += "file://xyz.openbmc_project.Snmp.Conf.service"

SRCREV = "519ecdde35556f0841732a5cc6d2f2dd915fd6fd"

S = "${WORKDIR}/git"

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.Snmp.Conf.service"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append() {
        install -d ${D}${systemd_system_unitdir}/
        install -d ${D}${libdir}/
        install -m 0644 ${UNPACKDIR}/xyz.openbmc_project.Snmp.Conf.service ${D}${systemd_system_unitdir}/
}

FILES:${PN}  += "${systemd_system_unitdir}/xyz.openbmc_project.Snmp.Conf.service"
