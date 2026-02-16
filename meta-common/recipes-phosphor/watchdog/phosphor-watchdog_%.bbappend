FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "489c97dbaf709eab3a691a6f3fca09504f3415f3"

SRC_URI += "file://0001-Added-Restart_cause-for-Power-Down.patch \
            file://0002-Added-PDKHOOK-support-for-WatchdogAction.patch \
           "

DEPENDS:append = " libpdkhook "
RDEPENDS:${PN}:append = " libpdkhook "
