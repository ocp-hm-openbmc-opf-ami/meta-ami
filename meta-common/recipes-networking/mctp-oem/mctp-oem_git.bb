FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
LICENSE = "GPL-2.0-only"

LIC_FILES_CHKSUM = "file://LICENSE;md5=4cc91856b08b094b4f406a29dc61db21"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/mctp-oem.git;protocol=https;branch=main \
           "
SRCREV = "1fddd6929891b81a04d644d894bd3bab056e8e13"
PV = "1.0+git${SRCPV}"

S = "${WORKDIR}/git"

inherit meson 
# EXTRA_OEMESON += " -Dbuild-oem-mctp-pdk-c41a8=enabled "
EXTRA_OEMESON += " -Dbuild-oem-mctp-pdk=disabled "

RDEPENDS:${PN} = " bash "
DEPENDS:append = " libusb1 json-c boost sdbusplus phosphor-logging i2c-tools "

