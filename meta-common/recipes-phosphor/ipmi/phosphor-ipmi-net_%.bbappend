FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "426fcab8ba80e9e2f7ec205ac3a97482919d8055"

SRC_URI += " \
           file://0015-Add-to-warm-reset.patch \
           file://0016-Postpone-To-Wait-Network-Service.patch \
           file://0017-EIP-761466-Return-If-ReservedBit-used.patch \
           file://0001-Fixed-the-coredump-issue-in-rmcpping.patch \
           file://0018-Support-IPv4-and-IPv6-Header-Parameters.patch \
           file://0308-CheckLockStatus-For-IpmiUsers.patch \
           "

python Add_DefaultUser_if_debugtweaks_not_enabled() {
    if 'debug-tweaks' not in d.getVar('EXTRA_IMAGE_FEATURES', True).split():
        d.appendVar('SRC_URI', " file://0308-Allow-Default-User-To-Change-Password-Even-Expired-A.patch")
}

ALT_RMCPP_IFACE = "hostusb0"
SYSTEMD_SERVICE:${PN} += " \
                          ${PN}@${ALT_RMCPP_IFACE}.service \
                          ${PN}@${ALT_RMCPP_IFACE}.socket \
                         "
