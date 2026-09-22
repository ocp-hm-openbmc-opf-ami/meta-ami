FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SUMMARY = "libapisensor library"
DESCRIPTION="A library to get sensor readings from hardware.  Used by dbus-sensors APISensor reactor"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"
 
SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/libapisensor.git;protocol=https;branch=main \
           file://0001-meson-avoid-absolute-Boost-library-path.patch \
           "
SRCREV = "0916ddd437852a1e4ada30629f3c960b86f0940b"
 
PV = "1.0.0"
 
S = "${UNPACKDIR}/git"
 
DEPENDS = " \
    boost \
    i2c-tools \
    libgpiod \
    liburing \
    nlohmann-json \
    phosphor-logging \
    sdbusplus \
    "
 
inherit pkgconfig meson systemd

FILES:${PN} += "${libdir}/libapisensor.so*"
