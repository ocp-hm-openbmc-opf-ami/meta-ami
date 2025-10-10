FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
	file://CVE-2025-26466.patch \
	file://CVE-2025-32728.patch \
	"
