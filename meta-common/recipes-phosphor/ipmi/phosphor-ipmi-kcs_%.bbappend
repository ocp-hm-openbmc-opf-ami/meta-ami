FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "9867112ceb0ae372851384f8c580ebea6ba67217"

SRC_URI += " \
	   file://0001-Add-to-warm-reset.patch \
	   file://0002-Workaround-on-Open-Source-PR-35.patch \
           "
