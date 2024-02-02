FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "e0602aaf7c721438bba08b3a5edaedaa3e427346"

SRC_URI += " \
	   file://0001-Add-to-warm-reset.patch \
           "
