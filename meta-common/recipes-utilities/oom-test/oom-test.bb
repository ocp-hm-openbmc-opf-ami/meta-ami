SUMMARY = "OOM Test App"
DESCRIPTION = "OOM (Out Of Memory) Test Application"

inherit meson

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta-core/meta/files/common-licenses/Intel-BMC-Base;md5=f66be55877b5b739110e445efdcf5fbc"

SRC_URI = "\
    file://meson.build;subdir=${BP} \
    file://oom-test.c;subdir=${BP} \
    "
