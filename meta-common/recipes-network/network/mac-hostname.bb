SUMMARY = "To set hostname combining with current MAC address."
DESCRIPTION = "Setting hostname with MAC address of eth0."

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

RDEPENDS:${PN} += "bash"
LICENSE = "CLOSED"


SRC_URI = "file://hostname-setting \
           file://mac-hostname.service \
"


inherit obmc-phosphor-systemd


SYSTEMD_SERVICE:${PN} += "${PN}.service"

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/hostname-setting ${D}${bindir}
}
