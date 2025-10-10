SUMMARY = "libespi"
DESCRIPTION = "Provides APIs for sending and receiving eSPI commands"

SRC_URI = "git://git@github.com/intel-bmc/firmware.bmc.openbmc.libraries.libespi.git;protocol=ssh;branch=main"
SRCREV = "7bce6014714b78b1719c39899c80560c4eb804ab"

S = "${WORKDIR}/git"

PV = "1.0+git${SRCPV}"

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta-core/meta/files/common-licenses/Intel-BMC-Base;md5=f66be55877b5b739110e445efdcf5fbc"

DEPENDS = "boost"

inherit meson
