SUMMARY = "SPDM Application Library"
DESCRIPTION = "Library for SPDM applications"

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta-core/meta/files/common-licenses/Intel-BMC-FWSEC;md5=8ad5886152d8fa09daa41fbe51fff047"


inherit pkgconfig meson

DEPENDS += " systemd \
            phosphor-logging \
            phosphor-dbus-interfaces \
            boost \
            mctpwplus \
            libspdm \
            "

SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/firmware.bmc.openbmc.libraries.spdmapplib.git;protocol=https;branch=main"

S = "${WORKDIR}/git"
SRCREV = "e9cf0c96af5d8cc4bc918739da0b153e0a3d1ca9"
PV = "1.0+git${SRCPV}"

EXTRA_OEMESON = "-Dyocto_dep='enabled'"

