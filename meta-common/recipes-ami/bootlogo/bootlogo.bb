DESCRIPTION = "clear bootlogo after bmc boot complete"
PR = "r1"
PV = "0.1"

LICENSE = "CLOSED"

SRC_URI = "file://bootlogo-clear.sh \
           "
inherit systemd
inherit obmc-phosphor-systemd

DEPENDS = "systemd"
RDEPENDS:${PN} = "bash"

SYSTEMD_PACKAGES = "${PN}"
do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/bootlogo-clear.sh ${D}/${bindir}/
}

SYSTEMD_SERVICE:${PN} = "psplash-clear.service"
