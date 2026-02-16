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
SRC_URI += "file://xyz.openbmc_project.Snmp.Conf.service"

SRCREV = "c50c41030a3a8305e83d910a23202850b6260bda"

S = "${WORKDIR}/git"

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.Snmp.Conf.service"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append() {
        install -d ${D}${systemd_system_unitdir}/
        install -d ${D}${libdir}/
        install -m 0644 ${WORKDIR}/xyz.openbmc_project.Snmp.Conf.service ${D}${systemd_system_unitdir}/
}

FILES:${PN}  += "${systemd_system_unitdir}/xyz.openbmc_project.Snmp.Conf.service"
