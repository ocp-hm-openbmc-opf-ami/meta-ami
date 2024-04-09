# Restricted override ami-fw-update script

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
PROJECT_SRC_DIR := "${THISDIR}/files"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=33abf79b43490ccebfe76ef9882fd8de"
SRC_URI += "file://fwupd-restricted.sh"
SRC_URI += "file://apply-onreset.service"
SRC_URI += "file://applyonreset.sh"


# flash_eraseall
RDEPENDS:ami-fw-update += "mtd-utils"
# wget tftp scp
RDEPENDS:ami-fw-update += "busybox dropbear"
# mkfs.vfat, parted
RDEPENDS:ami-fw-update += "dosfstools dtc"

RDEPENDS:ami-fw-update += "bash"
RDEPENDS:ami-fw-update += "systemd"
inherit systemd
inherit obmc-phosphor-systemd
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "apply-onreset.service"

do_install:append() {
        install -d ${D}${bindir}
        install -m 0755 ${WORKDIR}/fwupd-restricted.sh ${D}${bindir}/fwupd.sh
        install -m 0755 ${WORKDIR}/applyonreset.sh ${D}${bindir}/applyonreset.sh
}

