SUMMARY = "MCTP Setup"
DESCRIPTION = "Intel specific mctp logic"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=3b83ef96387f14655fc854ddc3c6bd57"

SRC_URI = "git://git@git.ami.com/core/ami-bmc/one-tree/intel/firmware.bmc.openbmc.applications.kmctp-setup.git;protocol=ssh;branch=oks-dev"

SRCREV:intel-ast2700 = "7016d3396b8eb8b510d818a412c2b9cfde532480"
SRCREV = "22ce062174e86e53ea9057e2551b4dafb41a0ebc"

S = "${UNPACKDIR}/git"

PV = "1.0+git${SRCPV}"

inherit meson pkgconfig systemd

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SYSTEMD_SERVICE:${PN} = "com.intel.mctp-setup.service"

DEPENDS += " \
    systemd \
    sdbusplus \
    phosphor-logging \
    boost \
    libtinyxml2 \
    i2c-tools \
    "

EXTRA_OEMESON = "-Dtests=disabled"

FILES:${PN} += "${systemd_system_unitdir}/com.intel.mctp-setup.service"
