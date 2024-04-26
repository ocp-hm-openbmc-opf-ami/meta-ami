FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
RDEPENDS:${PN}-health-monitor:remove = "phosphor-health-monitor"
RDEPENDS:${PN}-leds:remove = "phosphor-led-manager-faultmonitor"
RDEPENDS:${PN}-leds:remove = "phosphor-led-manager"
