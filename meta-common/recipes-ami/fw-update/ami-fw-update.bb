# Restricted override ami-fw-update script

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
PROJECT_SRC_DIR := "${THISDIR}/files"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=65a69a674f34a9f30737c9f0abd4fc5c"
SRC_URI += "file://fwupd-restricted.sh"
SRC_URI += "file://apply-onreset.service"
SRC_URI += "file://applyonreset.sh"
SRC_URI += "file://usb-ctrl"


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
	if ${@bb.utils.contains('OBMC_IMAGE_EXTRA_INSTALL','phosphor-misc-usb-ctrl','false','true',d)}; then
                install -m 0755 ${WORKDIR}/usb-ctrl ${D}${bindir}/
        fi
}

