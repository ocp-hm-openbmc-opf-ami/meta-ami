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


SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/snmp-agent.git;branch=main;protocol=https"
SRC_URI += "file://xyz.openbmc_project.Snmp.SnmpAgent.service"

SRCREV = "ecb3a9a6f8f8c23ad5d35b5e0bedb5506ad91b2c"

S = "${WORKDIR}/git"

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.Snmp.SnmpAgent.service"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


do_install:append() {
        install -d ${D}${systemd_system_unitdir}/
        install -m 0644 ${WORKDIR}/xyz.openbmc_project.Snmp.SnmpAgent.service ${D}${systemd_system_unitdir}/
}

FILES:${PN}  += "${systemd_system_unitdir}/xyz.openbmc_project.Snmp.SnmpAgent.service"
