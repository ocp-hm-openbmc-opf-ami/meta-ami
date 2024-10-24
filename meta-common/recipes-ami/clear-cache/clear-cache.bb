SUMMARY = "Removing the dropcache periodically"
DESCRIPTION = "This recipe installs a systemd service to remove the dropcache"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=33abf79b43490ccebfe76ef9882fd8de"

FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"
 
SRC_URI = "file://clear-cache.service \
           file://clear-cache.sh"


do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/clear-cache.sh ${D}${bindir}/
}

RDEPENDS:clear-cache += "bash"
RDEPENDS:clear-cache += "systemd"

SYSTEMD_PACKAGES = "${PN}" 

# Ensure the service is enabled
SYSTEMD_SERVICE:${PN} = "clear-cache.service"
SYSTEMD_AUTO_ENABLE = "enable"
 
inherit systemd
inherit obmc-phosphor-systemd
