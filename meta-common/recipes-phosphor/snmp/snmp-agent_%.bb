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


SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/snmp-agent.git;branch=Added_changes_to_enable_and_disable_smtp_via_SNMP;protocol=https"
SRC_URI += "file://xyz.openbmc_project.Snmp.SnmpAgent.service"

SRCREV = "8425e612b5b58a62e3637597906f144ac7843129"

S = "${WORKDIR}/git"

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.Snmp.SnmpAgent.service"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


do_install:append() {
        install -d ${D}${systemd_system_unitdir}/
        install -m 0644 ${WORKDIR}/xyz.openbmc_project.Snmp.SnmpAgent.service ${D}${systemd_system_unitdir}/
}

FILES:${PN}  += "${systemd_system_unitdir}/xyz.openbmc_project.Snmp.SnmpAgent.service"
