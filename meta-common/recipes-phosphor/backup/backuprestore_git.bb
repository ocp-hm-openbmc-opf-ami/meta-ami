SUMMARY = "backuprestore Backend implementation"
DESCRIPTION = "Backup and Restore backend implementing Backup and Restoring Configurating"
LICENSE = "CLOSED"
# Modify these as desired
PV = "1.0+git${SRCPV}"
#SRCREV = "37b6dd71852e66ce8a1352732d7ed105cf579c88"
# Use AUTOREV to get the latest revision from the repository
SRCREV = "${AUTOREV}"

inherit meson pkgconfig
inherit obmc-phosphor-dbus-service


DEPENDS += "boost"
DEPENDS += "sdbusplus"
DEPENDS += "sdeventplus"
DEPENDS += "phosphor-dbus-interfaces"
DEPENDS += "systemd"
DEPENDS += "phosphor-logging"
DEPENDS += "nlohmann-json"

DBUS_PACKAGES = "${PN}"

SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/backup-restore.git;protocol=https;branch=backuprestore-start"
SRC_URI += "file://xyz.openbmc_project.Backup.BackupRestore.service"
SRC_URI += "file://backupconf.json"

S = "${WORKDIR}/git"

DBUS_SERVICE:${PN} += "xyz.openbmc_project.Backup.BackupRestore.service"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append() {
	install -d ${D}${systemd_system_unitdir}/
	install -d ${D}/var/backups/
	install -m 0644 ${WORKDIR}/xyz.openbmc_project.Backup.BackupRestore.service ${D}${systemd_system_unitdir}/
	install -m 0644 ${WORKDIR}/backupconf.json ${D}/var/backups/
}


FILES:${PN}  += "${systemd_system_unitdir}/xyz.openbmc_project.Backup.BackupRestore.service"

