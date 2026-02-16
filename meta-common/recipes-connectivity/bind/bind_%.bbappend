FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
	file://CVE-2025-40778.patch \
	file://CVE-2025-40780.patch \
	"
