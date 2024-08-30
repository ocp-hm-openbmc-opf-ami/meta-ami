FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SUMMARY = "Enable eMMC support in BMC"
DESCRIPTION ="Enabling eMMC support - Mounting the eMMC and creating file system."

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COREBASE}/openbmc-meta-intel/meta/files/common-licenses/Intel-BMC-Base;md5=f66be55877b5b739110e445efdcf5fbc"

SRC_URI += " file://enable-emmc.sh "

inherit obmc-phosphor-systemd

RDEPENDS:${PN} = "bash"

do_install() {
        install -d ${D}${bindir}
        install -m 0755 ${WORKDIR}/enable-emmc.sh ${D}${bindir}/
}

SYSTEMD_SERVICE:${PN} = "com.intel.eMMCEnable.service"
