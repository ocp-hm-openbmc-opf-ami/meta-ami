FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#SRCREV = "0736e213fa0cc2d2b3463ea8918765ce3b158574"

SRCREV = "9898d612c3f3fbacd08daff934a83bdb2a7c0dd5"

SRC_URI += " \
	   file://0004-Add-to-warm-reset.patch \
	   file://0005-Ipmbbridged-adds-generator-ID-to-payload.patch \
           "
