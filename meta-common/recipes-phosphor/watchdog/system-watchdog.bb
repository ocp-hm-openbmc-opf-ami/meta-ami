SUMMARY = "System watchdog"
DESCRIPTION = "BMC hardware watchdog service that is used to reset BMC \
               when unrecoverable events occurs"

inherit allarch
inherit obmc-phosphor-systemd

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta-core/meta/files/common-licenses/Intel-BMC-Base;md5=f66be55877b5b739110e445efdcf5fbc"

SYSTEMD_SERVICE:${PN} += "system-watchdog.service"
SYSTEMD_ENVIRONMENT_FILE:${PN} += "obmc/system-watchdog/system-watchdog.conf"
