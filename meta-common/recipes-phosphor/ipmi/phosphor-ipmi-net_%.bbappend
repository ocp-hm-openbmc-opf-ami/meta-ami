FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#removing old SRCREV , latest SRCREV mentioned in openbmc-meta-intel 


SRC_URI += " \
           file://0015-Add-to-warm-reset.patch \
           file://0016-Postpone-To-Wait-Network-Service.patch \
           file://0017-EIP-761466-Return-If-ReservedBit-used.patch \
           "
ALT_RMCPP_IFACE = "usb0"
SYSTEMD_SERVICE:${PN} += " \
                          ${PN}@${ALT_RMCPP_IFACE}.service \
                          ${PN}@${ALT_RMCPP_IFACE}.socket \
                         "
