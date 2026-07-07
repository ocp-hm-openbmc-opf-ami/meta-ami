SUMMARY = "libmctp:intel"
DESCRIPTION = "Implementation of MCTP(DMTF DSP0236)"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/libmctp.git;protocol=https;branch=main"
SRCREV = "14b71e2fc1a679cb21fb59efe9f5cbfae3b5d579"

S = "${UNPACKDIR}/git"

PV = "1.0+git${SRCPV}"

LICENSE = "Apache-2.0 | GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://LICENSE;md5=0d30807bb7a4f16d36e96b78f9ed8fae"

inherit cmake

DEPENDS += "i2c-tools"
