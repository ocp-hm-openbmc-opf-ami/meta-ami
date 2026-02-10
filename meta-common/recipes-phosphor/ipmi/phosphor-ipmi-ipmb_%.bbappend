FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "3ef588d54cddafc1f5777fef8653aa0388ca6d44"

SRC_URI += " \
	   file://0004-Add-to-warm-reset.patch \
	   file://0005-Ipmbbridged-adds-generator-ID-to-payload.patch \
           "
