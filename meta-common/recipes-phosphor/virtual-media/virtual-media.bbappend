FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/firmware.bmc.openbmc.applications.virtual-media;branch=main;protocol=https"


SRCREV = "743a7a487be8c58160751ec6aac54cb879bec1ee"

RDEPENDS:${PN} = "nbd-client nbdkit nfs-export-root"

SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('MULTI_HOST_DEFAULT_MODE', '1', 'xyz.openbmc_project.VirtualMedia1.service', '', d)}"

PACKAGECONFIG:append = "${@bb.utils.contains('MULTI_HOST_DEFAULT_MODE', '1', ' dual_node', '', d)}"
PACKAGECONFIG[dual_node] = "-Ddual_node=enabled,-Ddual_node=disabled"

FILES_${PN} += "${systemd_system_unitdir}/xyz.openbmc_project.VirtualMedia*.service"

