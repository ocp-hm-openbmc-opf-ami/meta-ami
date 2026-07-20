FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://${BPN}@bond0.service \
            file://${BPN}@bond0.socket \
           "

ALT_RMCPP_IFACE = "eth1"
SYSTEMD_SERVICE:${PN}:append = " \
    ${PN}@${ALT_RMCPP_IFACE}.service \
    ${PN}@${ALT_RMCPP_IFACE}.socket \
    "

do_install:append() {
    install -m 0644 ${UNPACKDIR}/${BPN}@bond0.service \
        ${D}${systemd_system_unitdir}/${BPN}@bond0.service
    install -m 0644 ${UNPACKDIR}/${BPN}@bond0.socket \
        ${D}${systemd_system_unitdir}/${BPN}@bond0.socket
}

FILES:${PN} += " \
                ${systemd_system_unitdir}/${PN}@bond0.service \
                ${systemd_system_unitdir}/${PN}@bond0.socket \
               "

