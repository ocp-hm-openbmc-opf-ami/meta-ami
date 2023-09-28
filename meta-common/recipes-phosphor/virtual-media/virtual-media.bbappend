FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


RDEPENDS:${PN} = "nbd-client nbdkit nfs-export-root"

