FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

S = "${UNPACKDIR}"
SRC_URI:append = "file://ami-syncd \
           file://ami-sync-tmp.conf \
"

FILES:${PN} += "${systemd_system_unitdir}/ami-sync.service \
                ${libdir}/tmpfiles.d/ami-sync-tmp.conf"

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/ami-syncd ${D}${bindir}/ami-syncd
    install -d ${D}${libdir}/tmpfiles.d
    install -m 0644 ${S}/ami-sync-tmp.conf ${D}${libdir}/tmpfiles.d/
}

