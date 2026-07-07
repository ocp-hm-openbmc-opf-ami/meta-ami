SUMMARY = "Sync MAC Address from Uboot"
DESCRIPTION = "Make the MAC Address is as the same as setting in Uboot"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

RDEPENDS:${PN} += "bash"
LICENSE = "CLOSED"


SRC_URI = "file://uboot-mac-addr.sh \
           file://uboot-mac-addr.service \
"


inherit obmc-phosphor-systemd


SYSTEMD_SERVICE:${PN} += "${PN}.service"

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/uboot-mac-addr.sh ${D}${bindir}
}
