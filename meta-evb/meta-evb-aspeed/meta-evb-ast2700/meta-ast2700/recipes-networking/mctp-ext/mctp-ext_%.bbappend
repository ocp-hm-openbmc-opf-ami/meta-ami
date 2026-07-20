FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
	file://mctp_ext_options.json \
	"

EXTRA_OEMESON:append = " \
    -Dbuild-reactor=enabled \
    -Dbuild-mctp-i3c-daemon=disabled \
    -Ddefault-local-eid=10 \
    -Dmctp-i2c=enabled \
    -Dmctp-i2c-net=1 \
    -Dmctp-i2c-arp=enabled \
    -Dmctp-i2c-whitelist=12,13,1d,32 \
    -Dmctp-i2c-poll-interval=60 \
    -Dmctp-i3c=enabled \
    -Dmctp-i3c-net=8 \
    -Dmctp-i3c-poll-interval=120 \
    -Dmctp-pcie=enabled \
    -Dmctp-pcie-net=3 \
    -Dmctp-pcie-role=endpoint \
    -Dmctp-pcie-poll-interval=60 \
    -Dmctp-usb=enabled \
    -Dmctp-usb-net=5 \
    -Dmctp-usb-hotplug=enabled \
    -Dmctp-usb-poll-interval=60 \
    -Dmctp-routing-table-poll-interval=60 \
    -Dplatform-soc=aspeed-2600 \
"

do_install:append () {
	# Override JSON config with platform-specific version
	install -d ${D}${datadir}/mctp
	install -m 0644 ${UNPACKDIR}/mctp_ext_options.json ${D}${datadir}/mctp/mctp_ext_options.json
}
