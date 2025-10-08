SUMMARY = "libpldm_intel"
DESCRIPTION = "Provides encode/decode APIs for PLDM specifications"

SRC_URI = "git://git@github.com/intel-bmc/firmware.bmc.openbmc.libraries.libpldm.git;protocol=ssh;branch=main"
SRCREV = "c7eaebd454ec1b3f94e54b5ee617acb57046ea4b"

S = "${WORKDIR}/git"

PV = "1.0+git${SRCPV}"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

inherit cmake

DEPENDS += " \
    gtest \
    "
