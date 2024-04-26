FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:ast-mmc = " \
    file://u-boot-env.txt \
    "