FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += " \
           file://0001-Added-change-to-launch-Multisol-session-via-IPMI.patch \
           file://0002-Fix-to-Handle-payload-instance-for-MultiSOL.patch \
           "

ALT_RMCPP_IFACE_ETH1 = "eth1"
SYSTEMD_SERVICE:${PN} += " \
     ${PN}@${ALT_RMCPP_IFACE_ETH1}.service \
     ${PN}@${ALT_RMCPP_IFACE_ETH1}.socket \
     "

PACKAGECONFIG:append ="${@bb.utils.contains('MULTI_SOL_ENABLED', '1', ' multi_sol', ' ', d)}"
PACKAGECONFIG[multi_sol] = "-Dmulti_sol=enabled,-Dmulti_sol=disabled"

