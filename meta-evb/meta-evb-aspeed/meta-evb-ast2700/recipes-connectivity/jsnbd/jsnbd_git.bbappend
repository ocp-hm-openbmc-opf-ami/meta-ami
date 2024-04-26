FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

FILES:${PN}:append = " ${sysconfdir}/nbd-proxy/state"
FILES:${PN}:append = " ${sysconfdir}/nbd-proxy/config.json "

SRC_URI:append = " file://state_hook"
SRC_URI:append = " file://config.json"

do_install:append() {
    install -d ${D}${sysconfdir}/nbd-proxy/
    install -m 0755 ${WORKDIR}/state_hook ${D}${sysconfdir}/nbd-proxy/state
    install -m 0644 ${WORKDIR}/config.json ${D}${sysconfdir}/nbd-proxy/config.json
}
