DESCRIPTION = "PLDM OEM hook functions library"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=65a69a674f34a9f30737c9f0abd4fc5c"

SRC_URI = "file://meson.build \
           file://src \
        "

S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"

# Cross-compile for the target
inherit lib_package pkgconfig meson

DEPENDS = " ot-pldm "
DEPENDS += " phosphor-logging "

