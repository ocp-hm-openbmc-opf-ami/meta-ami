FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:ast-mmc = " file://u-boot-env.txt"
SRC_URI:append:ast-ufs = " file://u-boot-env-ufs.txt"
