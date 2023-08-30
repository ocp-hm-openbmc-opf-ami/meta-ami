FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-virtual-media-https-support.patch \
            file://0002-virtual-media-add-nfs-support.patch \
            file://0003-virtual-media-udc.patch \
           "

RDEPENDS:${PN} = "nbd-client nbdkit nfs-export-root"

