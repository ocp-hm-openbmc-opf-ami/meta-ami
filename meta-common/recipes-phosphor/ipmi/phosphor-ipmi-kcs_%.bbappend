FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "21020c56c03e7f99fa52cb1ea7843dafa7ecb2b5"

SRC_URI += " \
	   file://0001-Add-to-warm-reset.patch \
           "
