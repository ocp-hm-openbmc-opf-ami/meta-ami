FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

ALT_RMCPP_IFACE_ETH1 = "eth1"
SYSTEMD_SERVICE:${PN} += " \
     ${PN}@${ALT_RMCPP_IFACE_ETH1}.service \
     ${PN}@${ALT_RMCPP_IFACE_ETH1}.socket \
     "
