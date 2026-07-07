SUMMARY = "libpldm_intel"
DESCRIPTION = "Provides encode/decode APIs for PLDM specifications"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/libpldm.git;protocol=https;branch=main"
SRCREV = "4ba1ff6e1751c7c9e2b0cab949e3d8544288cb4e"

S = "${UNPACKDIR}/git"

PV = "1.0+git${SRCPV}"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

inherit cmake

DEPENDS += " \
    gtest \
    "
