LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/GPL-2.0-or-later;md5=fed54355545ffd980b814dab4a3b312c"

inherit pkgconfig meson

SRC_URI = " git://github.com/AspeedTech-BMC/aspeed_app.git;protocol=https;branch=${BRANCH} "
SRC_URI += "file://0001-Support-MCTP-I3C-for-slave-dev.patch"

PV = "1.0+git${SRCPV}"

# Tag for v00.01.11
SRCREV = "75e5bd45a62e87142dda39a601d7f9ec4ed9314a"
BRANCH = "master"

S = "${WORKDIR}/git"

DEPENDS += "openssl"
RDEPENDS:${PN} += "openssl"

FILES:${PN}:append = " /usr/share/* "
