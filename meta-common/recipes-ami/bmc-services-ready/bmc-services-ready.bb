SUMMARY = "Monitor the BMC service status"
DESCRIPTION = "Installs a script to monitor service status with configurable interval, retry count, and service list"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=65a69a674f34a9f30737c9f0abd4fc5c"

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI = "file://bmc-services-ready.sh \
           file://bmc-services-ready.conf \
           file://bmc-services-ready.service"

inherit systemd

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/bmc-services-ready.sh ${D}${bindir}/bmc-services-ready.sh
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/bmc-services-ready.conf ${D}${sysconfdir}/bmc-services-ready.conf
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/bmc-services-ready.service ${D}${systemd_system_unitdir}/bmc-services-ready.service
}

RDEPENDS:${PN} += "bash"

SYSTEMD_SERVICE:${PN} = "bmc-services-ready.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"
