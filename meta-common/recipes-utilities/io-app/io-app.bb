SUMMARY = "IO App"
DESCRIPTION = "IO application for accessing memory-mapped IO regions on the BMC"

inherit cmake

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta-core/meta/files/common-licenses/Intel-BMC-Base;md5=f66be55877b5b739110e445efdcf5fbc"

SRC_URI = "\
    file://CMakeLists.txt;subdir=${BP} \
    file://io-app.c;subdir=${BP} \
    "
