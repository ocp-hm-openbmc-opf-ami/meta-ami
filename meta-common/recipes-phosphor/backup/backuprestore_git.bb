SUMMARY = "backuprestore Backend implementation"
DESCRIPTION = "Backup and Restore backend implementing Backup and Restoring Configurating"
LICENSE = "CLOSED"
# Modify these as desired
PV = "1.0+git${SRCPV}"
SRCREV = "9495582c34e440ac79f4d728bce7dba680954d05"

inherit meson pkgconfig
inherit obmc-phosphor-dbus-service


DEPENDS += "boost"
DEPENDS += "sdbusplus"
DEPENDS += "sdeventplus"
DEPENDS += "phosphor-dbus-interfaces"
DEPENDS += "systemd"
DEPENDS += "phosphor-logging"
DEPENDS += "nlohmann-json"
DEPENDS += "openssl"

DBUS_PACKAGES = "${PN}"

SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/backup-restore.git;protocol=https;branch=main"
SRC_URI += "file://xyz.openbmc_project.Backup.BackupRestore.service"
SRC_URI += "file://backupconf.json"

S = "${WORKDIR}/git"

DBUS_SERVICE:${PN} += "xyz.openbmc_project.Backup.BackupRestore.service"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append() {
	install -d ${D}${systemd_system_unitdir}/
	install -d ${D}/var/backups/
	install -d ${D}/etc/backups/
	install -m 0644 ${WORKDIR}/xyz.openbmc_project.Backup.BackupRestore.service ${D}${systemd_system_unitdir}/
	install -m 0644 ${WORKDIR}/backupconf.json ${D}/var/backups/
}


FILES:${PN}  += "${systemd_system_unitdir}/xyz.openbmc_project.Backup.BackupRestore.service"

