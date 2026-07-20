FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
           file://0001-Added-change-to-launch-Multisol-session-via-IPMI.patch \
           file://0002-Fix-to-Handle-payload-instance-for-MultiSOL.patch \
           "


SRC_URI += " \
            file://${BPN}@bond0.service \
            file://${BPN}@bond0.socket \
           "

ALT_RMCPP_IFACE_ETH1 = "eth1"
SYSTEMD_SERVICE:${PN} += " \
     ${PN}@${ALT_RMCPP_IFACE_ETH1}.service \
     ${PN}@${ALT_RMCPP_IFACE_ETH1}.socket \
     "

ALT_RMCPP_IFACE_ETH2 = "eth2"
SYSTEMD_SERVICE:${PN} += " \
     ${PN}@${ALT_RMCPP_IFACE_ETH2}.service \
     ${PN}@${ALT_RMCPP_IFACE_ETH2}.socket \
     "

ALT_RMCPP_IFACE_ETH3 = "eth3"
SYSTEMD_SERVICE:${PN} += " \
     ${PN}@${ALT_RMCPP_IFACE_ETH3}.service \
     ${PN}@${ALT_RMCPP_IFACE_ETH3}.socket \
     "


PACKAGECONFIG:append ="${@bb.utils.contains('MULTI_SOL_ENABLED', '1', ' multi_sol', ' ', d)}"
PACKAGECONFIG[multi_sol] = "-Dmulti_sol=enabled,-Dmulti_sol=disabled"


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

