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


SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/snmp-agent;protocol=https;branch=main"
SRC_URI += "file://xyz.openbmc_project.Snmp.Conf.service"

SRCREV = "1c0647ab9fc2292903d9f7623f722aeec8279ba7"

S = "${WORKDIR}/git"

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.Snmp.Conf.service"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append() {
        install -d ${D}${systemd_system_unitdir}/
        install -d ${D}${libdir}/
        install -m 0644 ${WORKDIR}/xyz.openbmc_project.Snmp.Conf.service ${D}${systemd_system_unitdir}/
}

FILES:${PN}  += "${systemd_system_unitdir}/xyz.openbmc_project.Snmp.Conf.service"
