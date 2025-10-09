FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://0001-lib-ecdsa-Add-ECDSA384-support.patch \
"
