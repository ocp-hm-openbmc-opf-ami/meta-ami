FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "7b534095425121afd42d669655a902aaaea5716b"

SRC_URI += " \
           file://0015-Add-to-warm-reset.patch \
           file://0016-Postpone-To-Wait-Network-Service.patch \
           file://0017-EIP-761466-Return-If-ReservedBit-used.patch \
           file://0002-Enabled-RMCP-Ping-and-reversed-IANA-no-while-receiving-RMCP-Pong.patch \
           "
ALT_RMCPP_IFACE = "usb0"
SYSTEMD_SERVICE:${PN} += " \
                          ${PN}@${ALT_RMCPP_IFACE}.service \
                          ${PN}@${ALT_RMCPP_IFACE}.socket \
                         "
