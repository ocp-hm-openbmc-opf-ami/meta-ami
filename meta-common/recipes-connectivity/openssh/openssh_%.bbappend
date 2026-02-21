FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
	file://CVE-2025-61985.patch \
	file://CVE-2025-61984.patch \
	"
