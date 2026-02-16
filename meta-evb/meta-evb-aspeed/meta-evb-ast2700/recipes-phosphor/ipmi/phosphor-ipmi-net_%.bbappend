ALT_RMCPP_IFACE = "eth1"
SYSTEMD_SERVICE:${PN}:append = " \
    ${PN}@${ALT_RMCPP_IFACE}.service \
    ${PN}@${ALT_RMCPP_IFACE}.socket \
    "
ALT_RMCPP_IFACE_BOND = "bond0"
SYSTEMD_SERVICE:${PN} += " \
    ${PN}@${ALT_RMCPP_IFACE_BOND}.service \
    ${PN}@${ALT_RMCPP_IFACE_BOND}.socket \
    "
