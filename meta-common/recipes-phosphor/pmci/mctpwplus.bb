SUMMARY = "MCTP Wrapper Library Plus"
DESCRIPTION = "Implementation of MCTP Wrapper Library Plus"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=3b83ef96387f14655fc854ddc3c6bd57"
SRC_URI = "git://git@github.com/intel-bmc/firmware.bmc.openbmc.libraries.mctpwplus.git;protocol=ssh;branch=main"
SRCREV = "4802b4c1f4ff38284c3e4f7e823d81574c84aad6"

S = "${WORKDIR}/git"

PV = "1.0+git${SRCPV}"

inherit meson pkgconfig

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEPENDS += " \
    systemd \
    sdbusplus \
    phosphor-logging \
    cli11 \
    "
#EXTRA_OECMAKE += "-DYOCTO_DEPENDENCIES=ON"
EXTRA_OEMESON:append = " -Dtests=disabled"

