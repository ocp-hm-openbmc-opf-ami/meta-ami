FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV_override = "b50504e9148ff8832151ec5ed13bc68a86e34843"

SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-net-ipmid.git;branch=integrate-onetree-latest;protocol=https;name=override;"

SRCREV_FORMAT = "override"
CXXFLAGS += "-DENABLE_RMCP_RMCPP_IN_IPV6"

# Expired-password restriction for the default user lives in command_table.cpp,
# guarded by ALLOW_ROOT_LOGIN: compiled in only when allow-root-login is NOT enabled.
CXXFLAGS += "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'allow-root-login', '-DALLOW_ROOT_LOGIN', '', d)}"

ALT_RMCPP_IFACE = "hostusb0"
SYSTEMD_SERVICE:${PN} += " \
                          ${PN}@${ALT_RMCPP_IFACE}.service \
                          ${PN}@${ALT_RMCPP_IFACE}.socket \
                          phosphor-ipmi-net-bond0-reconcile.service \
                         "

FILES:${PN} += " \
                ${systemd_system_unitdir}/${PN}@hostusb0.service \
                ${systemd_system_unitdir}/${PN}@hostusb0.socket \
                ${systemd_system_unitdir}/phosphor-ipmi-net-bond0-reconcile.service \
               "

SRC_URI += " \
            file://${BPN}@hostusb0.service \
            file://${BPN}@hostusb0.socket \
            file://phosphor-ipmi-net-bond0-reconcile.service \
           "

do_install:append() {
    install -m 0644 ${UNPACKDIR}/${BPN}@hostusb0.service \
        ${D}${systemd_system_unitdir}/${BPN}@hostusb0.service
    install -m 0644 ${UNPACKDIR}/${BPN}@hostusb0.socket \
        ${D}${systemd_system_unitdir}/${BPN}@hostusb0.socket
    install -m 0644 ${UNPACKDIR}/phosphor-ipmi-net-bond0-reconcile.service \
        ${D}${systemd_system_unitdir}/phosphor-ipmi-net-bond0-reconcile.service
}

NCSI_RMCPP_IFACE = "eth1"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-network-ncsi-support', \
                            '${PN}@${NCSI_RMCPP_IFACE}.service ${PN}@${NCSI_RMCPP_IFACE}.socket', \
                            '', d)}"
