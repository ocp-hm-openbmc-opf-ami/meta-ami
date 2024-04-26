SUMMARY = "PECI Library"
DESCRIPTION = "PECI Library"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=7becf906c8f8d03c237bad13bc3dac53"
inherit cmake

SRC_URI = "git://github.com/openbmc/libpeci;protocol=https;branch=master"

PV = "0.1+git${SRCPV}"
SRCREV = "7b11280d8e3113aecc4b9ce6e5d818268eb2122c"

S = "${WORKDIR}/git"

SRC_URI += "file://0001-initialize-unintialized-var.patch"

