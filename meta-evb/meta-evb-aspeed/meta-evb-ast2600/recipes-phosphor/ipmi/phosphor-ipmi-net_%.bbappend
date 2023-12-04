FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += " \
           file://0001-Changes-are-added-to-support-multisol.patch \
           file://0002-Added-fix-to-launch-SOL-session-in-Multi-SOL-support.patch \
           "

ALT_RMCPP_IFACE = "eth1"
SYSTEMD_SERVICE:${PN} += " \
     ${PN}@${ALT_RMCPP_IFACE}.service \
     ${PN}@${ALT_RMCPP_IFACE}.socket \
     "

PACKAGECONFIG:append ="${@bb.utils.contains('MULTI_SOL_ENABLED', '1', ' multi_sol', ' ', d)}"
PACKAGECONFIG[multi_sol] = "-Dmulti_sol=enabled,-Dmulti_sol=disabled"

