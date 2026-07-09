FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
inherit obmc-phosphor-systemd

RDEPENDS:${PN} = " bash "

SRC_URI:append = " \
	"

# SYSTEMD_OVERRIDE:${PN} += "mctp-init.conf:mctpd.service.d/mctp-init.conf"

do_install:append () {
}
