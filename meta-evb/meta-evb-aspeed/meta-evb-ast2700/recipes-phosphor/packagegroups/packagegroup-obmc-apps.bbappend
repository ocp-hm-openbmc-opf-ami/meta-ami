FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
RDEPENDS:${PN}-health-monitor:remove = "phosphor-health-monitor"
