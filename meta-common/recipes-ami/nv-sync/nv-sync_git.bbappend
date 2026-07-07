FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://nv-sync.service.d/10-conditional.conf \
"

do_install:append() {
    # Install the drop-in override
    install -d ${D}${systemd_system_unitdir}/nv-sync.service.d
    install -m 0644 ${UNPACKDIR}/nv-sync.service.d/10-conditional.conf \
        ${D}${systemd_system_unitdir}/nv-sync.service.d/10-conditional.conf

    # Install the enable flag so nv-sync runs by default
    install -d ${D}/etc
    touch ${D}/etc/nv-sync-enable
}

FILES:${PN} += " \
    ${systemd_system_unitdir}/nv-sync.service.d/10-conditional.conf \
    /etc/nv-sync-enable \
"
