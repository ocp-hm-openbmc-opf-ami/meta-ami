FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/firmware.bmc.openbmc.applications.virtual-media;branch=main;protocol=https"


SRCREV = "b0ca4aa34cb4dcf5a5aa3c197751a427f48483e8"

RDEPENDS:${PN} = "nbd-client nbdkit nfs-export-root"

