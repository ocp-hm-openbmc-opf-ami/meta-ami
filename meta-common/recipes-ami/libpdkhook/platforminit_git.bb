SUMMARY = "PlatformInit"
DESCRIPTION = "This Package calls PlatformInit PDK Hooks Implemention"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=65a69a674f34a9f30737c9f0abd4fc5c"


DEPENDS:append = " libpdkhook "
RDEPENDS:${PN}:append = " libpdkhook "

SRC_URI = " \
           file://main.cpp \
           file://meson.build \
           file://platforminit.service \
          "

S = "${UNPACKDIR}"

inherit pkgconfig meson systemd
inherit obmc-phosphor-systemd

DEPENDS += " \
    boost \
    sdbusplus \
    phosphor-dbus-interfaces \
    phosphor-logging \
    systemd \
    "

SYSTEMD_SERVICE:${PN} += "platforminit.service"
FILES:${PN}  += "${systemd_system_unitdir}/platforminit.service"
