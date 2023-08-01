FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-AST2600-EVB-Power-Control.patch \
            file://0002-Removed-SIO_POWER_GOOD-and-IdButton.patch \
           "

