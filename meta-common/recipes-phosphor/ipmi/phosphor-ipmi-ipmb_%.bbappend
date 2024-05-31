FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "0736e213fa0cc2d2b3463ea8918765ce3b158574"

SRC_URI += " \
	   file://0004-Add-to-warm-reset.patch \
           "
