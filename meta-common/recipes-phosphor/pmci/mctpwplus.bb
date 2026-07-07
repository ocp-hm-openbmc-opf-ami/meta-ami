SUMMARY = "MCTP Wrapper Library Plus"
DESCRIPTION = "Implementation of MCTP Wrapper Library Plus"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=3b83ef96387f14655fc854ddc3c6bd57"
SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/mctpwplus.git;protocol=https;branch=main"
SRCREV = "e99c94c008e1ce176fc6d5a5248f9cbcdb63759c"

S = "${UNPACKDIR}/git"

PV = "1.0+git${SRCPV}"

inherit meson pkgconfig

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEPENDS += " \
    systemd \
    sdbusplus \
    phosphor-logging \
    cli11 \
    "
EXTRA_OEMESON:append = " -Dtests=disabled"

MESON_ENABLE_AF_MCTP = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'intel-af-mctp', 'enabled', 'disabled', d)}"
EXTRA_OEMESON:append = " -Dafmctp=${MESON_ENABLE_AF_MCTP}"
