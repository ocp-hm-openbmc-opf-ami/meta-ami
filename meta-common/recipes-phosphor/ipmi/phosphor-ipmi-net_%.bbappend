FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV_override = "9a26a4f66347de9de82f967b20f9825fb465289f"

SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-net-ipmid.git;branch=master;protocol=https;name=override;"

SRCREV_FORMAT = "override"
CXXFLAGS += "-DENABLE_RMCP_RMCPP_IN_IPV6"

python Add_DefaultUser_if_debugtweaks_not_enabled() {
    if 'allow-root-login' not in d.getVar('EXTRA_IMAGE_FEATURES', True).split():
        d.appendVar('SRC_URI', " file://0308-Allow-Default-User-To-Change-Password-Even-Expired-A.patch")
}

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
