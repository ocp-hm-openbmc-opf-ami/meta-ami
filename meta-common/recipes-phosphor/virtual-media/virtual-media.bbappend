FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/firmware.bmc.openbmc.applications.virtual-media;branch=main;protocol=https"


SRCREV = "d9e1f333335a067b153ac1560ac03f00ff42b9a3"

RDEPENDS:${PN} = "nbd-client nbdkit nfs-export-root"

SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('MULTI_HOST_DEFAULT_MODE', '1', 'xyz.openbmc_project.VirtualMedia1.service', '', d)}"

PACKAGECONFIG:append = "${@bb.utils.contains('MULTI_HOST_DEFAULT_MODE', '1', ' dual_node', '', d)}"
PACKAGECONFIG[dual_node] = "-Ddual_node=enabled,-Ddual_node=disabled"

FILES_${PN} += "${systemd_system_unitdir}/xyz.openbmc_project.VirtualMedia*.service"

