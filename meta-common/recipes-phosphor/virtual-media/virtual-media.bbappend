FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-virtual-media-https-support.patch \
            file://0002-virtual-media-add-nfs-support.patch \
            file://0003-Disable-kernel-page-caching-in-nbdkit-and-mount.cifs.patch \
            file://0004-virtual-media-eject-support.patch \
           "

RDEPENDS:${PN} = "nbd-client nbdkit nfs-export-root"

