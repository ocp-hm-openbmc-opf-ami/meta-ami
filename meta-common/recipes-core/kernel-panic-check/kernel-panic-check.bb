SUMMARY = "Kernel panic Check"
DESCRIPTION = "script tool to check if the reboot is caused by kernel panic \
               log the kernel panic to systemd journal, and also log to redfish \
              "

S = "${WORKDIR}"
SRC_URI = "file://kernel-panic-check.sh \
           file://kernel-panic-check.service \
"

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta-core/meta/files/common-licenses/Intel-BMC-Base;md5=f66be55877b5b739110e445efdcf5fbc"
RDEPENDS:${PN} += "bash logger-systemd"

inherit systemd

FILES:${PN} += "${systemd_system_unitdir}/kernel-panic-check.service"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/kernel-panic-check.service ${D}${systemd_system_unitdir}
    install -d ${D}${bindir}
    install -m 0755 ${S}/kernel-panic-check.sh ${D}/${bindir}/kernel-panic-check.sh
}

SYSTEMD_SERVICE:${PN} += " kernel-panic-check.service"
