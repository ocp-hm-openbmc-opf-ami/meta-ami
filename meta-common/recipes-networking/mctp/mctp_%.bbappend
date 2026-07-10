FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
inherit obmc-phosphor-systemd

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/mctp.git;protocol=https;branch=main \
           "
SRCREV = "d6eba0f37bd78889dece4781812a8ab58118c95f"

RDEPENDS:${PN} = " bash "
DEPENDS:append = " libusb1 json-c boost sdbusplus phosphor-logging i2c-tools"

SRC_URI:append = " \
	file://mctp-i2c-arp.sh \
	file://mctp-i2c-hotplug.sh \
	file://mctp-i3c-rescan.sh \
	file://mctp-discovery.sh \
	file://mctp-get-routing-table.sh \
	"

FILES:${PN} += "${libexecdir}/mctp/ "

do_install:append () {
	# Create libexec directory for mctp helper scripts
	install -d ${D}${libexecdir}/mctp
	install -m 0755 ${UNPACKDIR}/mctp-i2c-arp.sh ${D}${libexecdir}/mctp
	install -m 0755 ${UNPACKDIR}/mctp-i2c-hotplug.sh ${D}${libexecdir}/mctp
	install -m 0755 ${UNPACKDIR}/mctp-i3c-rescan.sh ${D}${libexecdir}/mctp
	install -m 0755 ${UNPACKDIR}/mctp-discovery.sh ${D}${libexecdir}/mctp
	install -m 0755 ${UNPACKDIR}/mctp-get-routing-table.sh ${D}${libexecdir}/mctp
}
