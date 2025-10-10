SUMMARY = "LPC tools"
DESCRIPTION = "command tool for LPC interface test on the BMC"

inherit cmake

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta-core/meta/files/common-licenses/Intel-BMC-Base;md5=f66be55877b5b739110e445efdcf5fbc"

SRC_URI = "\
    file://CMakeLists.txt;subdir=${BP} \
    file://lpc_drv.h;subdir=${BP} \
    file://lpc_cmds.c;subdir=${BP} \
    "
