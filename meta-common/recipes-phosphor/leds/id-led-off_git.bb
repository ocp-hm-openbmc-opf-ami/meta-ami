SUMMARY = "Turn off the ID LED"
DESCRIPTION = "Script to turn off the ID LED after BMC is ready"

S = "${WORKDIR}"
SRC_URI = "file://id-led-off.sh \
           file://id-led-off.service \
          "

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta-core/meta/files/common-licenses/Intel-BMC-Base;md5=f66be55877b5b739110e445efdcf5fbc"
RDEPENDS:${PN} += "bash"

inherit systemd

FILES:${PN} += "${systemd_system_unitdir}/id-led-off.service"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/id-led-off.service ${D}${systemd_system_unitdir}
    install -d ${D}${bindir}
    install -m 0755 ${S}/id-led-off.sh ${D}/${bindir}/id-led-off.sh
}

SYSTEMD_SERVICE:${PN} += " id-led-off.service"
