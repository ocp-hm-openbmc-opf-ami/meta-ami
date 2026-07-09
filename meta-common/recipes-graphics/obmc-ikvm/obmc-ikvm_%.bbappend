FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/obmc-ikvm;branch=main;protocol=https"


SRCREV = "a9328907bbc6235e8ffe04caf16802693c5145a2"
SYSTEMD_SERVICE:${PN}:remove = "obmc-ikvm.service"
SYSTEMD_SERVICE:${PN} += "start-ipkvm.socket start-dummy-ipkvm-client.service"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('MULTI_HOST_DEFAULT_MODE', '1', 'start-ipkvm1.service start-ipkvm1.socket', '', d)}"

PACKAGECONFIG:append = "${@bb.utils.contains('MULTI_HOST_DEFAULT_MODE', '1', ' dual_node', ' ', d)}"
PACKAGECONFIG[dual_node] = "-Ddual_node=enabled,-Ddual_node=disabled"

FILES:${PN} += "${systemd_system_unitdir}/start-ipkvm*"

