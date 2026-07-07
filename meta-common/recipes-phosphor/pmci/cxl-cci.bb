SUMMARY = "CXL CCI Daemon"
DESCRIPTION = "Implementation of CXL™ Type 3 Device CCI over MCTP(DTMF DSP0281)"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=3b83ef96387f14655fc854ddc3c6bd57"

SRC_URI = "git://git@github.com/intel-collab/firmware.bmc.openbmc.applications.cxl-cci.git;protocol=ssh;branch=main"
SRCREV = "7332f8ed3333f4fa7d289050d34dc21b0b28e5fa"

S = "${UNPACKDIR}/git"

PV = "1.0+git${SRCPV}"

OEMESON_SOURCEPATH = "${S}"

inherit meson pkgconfig systemd

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEPENDS += " \
    systemd \
    boost \
    sdbusplus \
    mctpwplus \
    "

EXTRA_OEMESON += "-Dyocto_dep=enabled"
EXTRA_OEMESON += "-Denable_cxl_cci_traces=enabled"

FILES:${PN} += "${systemd_system_unitdir}/xyz.openbmc_project.CXL.CCI.service"
SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.CXL.CCI.service"
