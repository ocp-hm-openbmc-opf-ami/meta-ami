FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
	"

EXTRA_OEMESON:append = " \
    -Dbuild-reactor=enabled \
    -Dbuild-mctp-i3c-daemon=disabled \
    -Ddefault-local-eid=10 \
    -Dmctp-i2c=enabled \
    -Dmctp-i2c-net=1 \
    -Dmctp-i2c-arp=enabled \
    -Dmctp-i2c-poll-interval=60 \
    -Dmctp-i3c=disabled \
    -Dmctp-i3c-net=8 \
    -Dmctp-i3c-poll-interval=120 \
    -Dmctp-pcie=disabled \
    -Dmctp-pcie-net=3 \
    -Dmctp-pcie-role=endpoint \
    -Dmctp-pcie-poll-interval=60 \
    -Dmctp-usb=disabled \
    -Dmctp-usb-net=5 \
    -Dmctp-usb-hotplug=enabled \
    -Dmctp-usb-poll-interval=60 \
    -Dmctp-routing-table-poll-interval=60 \
"

do_install:append () {
}
