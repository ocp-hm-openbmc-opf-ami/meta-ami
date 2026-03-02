FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/virtual-media.git;protocol=https;branch=main"


SRCREV = "b0ca4aa34cb4dcf5a5aa3c197751a427f48483e8"

RDEPENDS:${PN} = "nbd-client nbdkit nfs-export-root"

