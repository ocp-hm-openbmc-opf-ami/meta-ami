SUMMARY = "PHY Tool"
DESCRIPTION = "Linux MDIO register access"

PV = "1.0+git${SRCPV}"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=39bba7d2cf0ba1036f2a6e2be52fe3f0"

S = "${WORKDIR}/git"

SRC_URI = "git://github.com/wkz/phytool;protocol=https;branch=master"
SRCREV = "8882328c08ba2efb13c049812098f1d0cb8adf0c"

localdir = "/usr/local"
bindir = "${localdir}/bin"

do_compile () {
        oe_runmake
}

do_install () {
        # This is a guess; additional arguments may be required
        install -m 0755 -d ${D}${bindir}
        install -m 0755 ${S}/phytool ${D}${bindir}
}

