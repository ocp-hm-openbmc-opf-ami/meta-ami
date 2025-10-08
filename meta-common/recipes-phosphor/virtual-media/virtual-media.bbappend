FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/firmware.bmc.openbmc.applications.virtual-media;branch=main;protocol=https"


SRCREV = "7fda780788a26e8d0143bb6e6d7c35f313d1184b"

RDEPENDS:${PN} = "nbd-client nbdkit nfs-export-root"

