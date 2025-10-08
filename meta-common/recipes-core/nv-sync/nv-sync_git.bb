SUMMARY = "NV Overlay Sync"
DESCRIPTION = "Script to periodically sync the overlay to NV storage"

S = "${WORKDIR}"
SRC_URI = "file://nv-sync.service \
           file://nv-syncd \
           file://nv-sync-tmp.conf \
"

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta-core/meta/files/common-licenses/Intel-BMC-Base;md5=f66be55877b5b739110e445efdcf5fbc"

inherit systemd

RDEPENDS:${PN} += "bash"

FILES:${PN} += "${systemd_system_unitdir}/nv-sync.service \
                ${libdir}/tmpfiles.d/nv-sync-tmp.conf"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/nv-sync.service ${D}${systemd_system_unitdir}
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/nv-syncd ${D}${bindir}/nv-syncd
    install -d ${D}${libdir}/tmpfiles.d
    install -m 0644 ${WORKDIR}/nv-sync-tmp.conf ${D}${libdir}/tmpfiles.d/
}

SYSTEMD_SERVICE:${PN} += " nv-sync.service"
