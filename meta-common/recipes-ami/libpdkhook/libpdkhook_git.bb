SUMMARY = "PDK Hooks Library"
DESCRIPTION = "This Library contains PDK Hooks Implemention"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=65a69a674f34a9f30737c9f0abd4fc5c"


SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/libpdkhook.git;protocol=https;branch=integrate-onetree-3.1.1"
SRC_URI += " \
           file://0001-fix-boost-asio-compatibility.patch \
          "
SRCREV = "53be2ba6c08970716e5f085969c76de372a5a700"

S = "${WORKDIR}/git"
PV = "1.0"

inherit  meson pkgconfig  systemd

DEPENDS += " \
    boost \
    sdbusplus \
    phosphor-dbus-interfaces \
    phosphor-logging \
    systemd \
    "

do_install:append() {
    install -d ${D}${libdir}
    install -d ${D}${includedir}/
    install -m 0644 ${S}/*.hpp ${D}${includedir}/
}

FILES_${PN}-dev += "${includedir}/*.hpp"
