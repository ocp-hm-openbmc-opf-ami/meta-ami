SUMMARY = "MCTP Wrapper Library Plus"
DESCRIPTION = "Implementation of MCTP Wrapper Library Plus"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=615045c30a05cde5c0e924854d43c327"

SRC_URI = "git://git@github.com/intel-bmc/firmware.bmc.openbmc.libraries.mctpwplus.git;protocol=ssh;branch=main"
SRCREV = "bacc83457c6c666c4dbe8730216c26d6be5e1722"

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
EXTRA_OECMAKE += "-DYOCTO_DEPENDENCIES=ON"
