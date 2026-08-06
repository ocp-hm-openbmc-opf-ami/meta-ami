FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
inherit obmc-phosphor-systemd
LICENSE = "GPL-2.0-only"

LIC_FILES_CHKSUM = "file://LICENSE;md5=4cc91856b08b094b4f406a29dc61db21"

SRC_URI = "git://github.com/ocp-hm-openbmc-opf-ami/mctp-ext.git;protocol=https;branch=main \
           "
SRCREV = "fc8b0493e6472873f531e1501f40f02760e8aea0"
PV = "1.0+git${SRCPV}"

S = "${WORKDIR}/git"

inherit meson pkgconfig systemd

PACKAGECONFIG ??= " \
    ${@bb.utils.filter('DISTRO_FEATURES', 'systemd', d)} \
"

# mctpd will only be built if pkg-config detects libsystemd; in which case
# we'll want to declare the dep and install the service.
PACKAGECONFIG[systemd] = ",,systemd,libsystemd"
SYSTEMD_SERVICE:${PN} = "mctpreactor.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

RDEPENDS:${PN} = " bash "
DEPENDS:append = " libusb1 json-c boost sdbusplus phosphor-logging i2c-tools "

FILES:${PN} += "${datadir}/mctp/mctp_ext_options.json"

SRC_URI:append = " \
	file://mctpreactor.service \
	"
	
EXTRA_OEMESON:append = " \
    -Dbuild-reactor=enabled \
    -Dbuild-mctp-i3c-daemon=disabled \
"

do_install:append () {
	# Install systemd units
	install -d ${D}${systemd_system_unitdir}
	install -m 0644 ${UNPACKDIR}/mctpreactor.service ${D}${systemd_system_unitdir}/mctpreactor.service
}

