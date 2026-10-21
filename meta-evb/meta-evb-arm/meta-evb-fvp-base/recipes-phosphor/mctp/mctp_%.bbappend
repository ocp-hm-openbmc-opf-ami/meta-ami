FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

PV = "2.1"
SRCREV = "1953cea70f9290d46d219f2d7ac25662983e9424"

EXTRA_OEMESON = " \
    -Dtests=false \
"

SRC_URI:append = " \
  file://mctp-local.service \
  file://mctpd.conf \
"

SYSTEMD_SERVICE:${PN} += "mctp-local.service"

do_install:append() {
    install -m 0644 ${UNPACKDIR}/mctp-local.service ${D}${systemd_system_unitdir}/
    install -d ${D}/etc/
    install -m 0644 ${UNPACKDIR}/mctpd.conf ${D}/etc/mctpd.conf
}

