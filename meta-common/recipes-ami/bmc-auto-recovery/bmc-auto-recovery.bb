SUMMARY = "BMC Firmware Auto-Recovery (Single Image)"
DESCRIPTION = "Installs a boot-complete handler that resets auto-recovery U-Boot flags to defaults"

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=65a69a674f34a9f30737c9f0abd4fc5c"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    file://bmc-auto-recovery.sh \
    file://bmc-auto-recovery.service \
"

inherit systemd

RDEPENDS:${PN} = " \
    u-boot-fw-utils \
"

FILES:${PN} += " \
    ${systemd_system_unitdir}/bmc-auto-recovery.service \
"

do_install() {
    install -d ${D}${sbindir}
    install -m 0755 ${UNPACKDIR}/bmc-auto-recovery.sh ${D}${sbindir}/bmc-auto-recovery.sh

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/bmc-auto-recovery.service ${D}${systemd_system_unitdir}/bmc-auto-recovery.service
}

SYSTEMD_SERVICE:${PN} = "bmc-auto-recovery.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"
