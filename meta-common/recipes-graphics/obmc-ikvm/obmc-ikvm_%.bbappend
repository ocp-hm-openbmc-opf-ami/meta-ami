FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/obmc-ikvm;protocol=https;branch=integrate-onetree-3.1.1"


SRCREV = "6bd01641ab6674ea1647ea2d33cb6595ededd824"
SYSTEMD_SERVICE:${PN}:remove = "obmc-ikvm.service"
SYSTEMD_SERVICE:${PN} += "start-ipkvm.socket start-dummy-ipkvm-client.service"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('MULTI_HOST_DEFAULT_MODE', '1', 'start-ipkvm1.service start-ipkvm1.socket', '', d)}"

PACKAGECONFIG:append = "${@bb.utils.contains('MULTI_HOST_DEFAULT_MODE', '1', ' dual_node', ' ', d)}"
PACKAGECONFIG[dual_node] = "-Ddual_node=enabled,-Ddual_node=disabled"

FILES:${PN} += "${systemd_system_unitdir}/start-ipkvm*"

