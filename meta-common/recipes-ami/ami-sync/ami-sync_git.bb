SUMMARY = "NV Overlay Sync"
DESCRIPTION = "Script to periodically sync the overlay to NV storage"

S = "${UNPACKDIR}"
SRC_URI = "file://ami-sync.service \
           file://ami-syncd \
           file://ami-sync-tmp.conf \
           file://ami-sync.service.d/10-conditional.conf \
           file://ami-sync-enable \
"

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=65a69a674f34a9f30737c9f0abd4fc5c"

inherit systemd

RDEPENDS:${PN} += "bash"

FILES:${PN} += "${systemd_system_unitdir}/ami-sync.service \
                ${libdir}/tmpfiles.d/ami-sync-tmp.conf \
                ${systemd_system_unitdir}/ami-sync.service.d/10-conditional.conf \
                /etc/ami-sync-enable"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/ami-sync.service ${D}${systemd_system_unitdir}
    install -d ${D}${systemd_system_unitdir}/ami-sync.service.d
    install -m 0644 ${UNPACKDIR}/ami-sync.service.d/10-conditional.conf \
        ${D}${systemd_system_unitdir}/ami-sync.service.d/10-conditional.conf
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/ami-syncd ${D}${bindir}/ami-syncd
    install -d ${D}${libdir}/tmpfiles.d
    install -m 0644 ${UNPACKDIR}/ami-sync-tmp.conf ${D}${libdir}/tmpfiles.d/
    install -d ${D}/etc
    install -m 0644 ${UNPACKDIR}/ami-sync-enable ${D}/etc/ami-sync-enable
}

SYSTEMD_SERVICE:${PN} += " ami-sync.service"
