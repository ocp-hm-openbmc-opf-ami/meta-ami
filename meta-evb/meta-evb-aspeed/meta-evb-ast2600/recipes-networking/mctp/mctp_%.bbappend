FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
inherit obmc-phosphor-systemd

RDEPENDS:${PN} = " bash "

SRC_URI:append = " \
	"

EXTRA_OEMESON:append = " \
    -Dunsafe-recover-nil-uuid=false \
    -Dunsafe-writable-connectivity=false \
    -Dtests=false \
"

do_install:append () {
}
