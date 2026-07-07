FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += " \
	file://CVE-2025-7039.patch \
	file://CVE-2025-13601.patch \
	file://CVE-2025-14087.patch \
	file://CVE-2025-14512.patch \
	"
