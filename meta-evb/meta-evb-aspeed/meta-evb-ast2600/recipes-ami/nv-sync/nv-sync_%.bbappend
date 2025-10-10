FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

S = "${WORKDIR}"
SRC_URI:append = "file://nv-syncd \
           file://nv-sync-tmp.conf \
"

FILES:${PN} += "${systemd_system_unitdir}/nv-sync.service \
                ${libdir}/tmpfiles.d/nv-sync-tmp.conf"

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/nv-syncd ${D}${bindir}/nv-syncd
    install -d ${D}${libdir}/tmpfiles.d
    install -m 0644 ${WORKDIR}/nv-sync-tmp.conf ${D}${libdir}/tmpfiles.d/
}

