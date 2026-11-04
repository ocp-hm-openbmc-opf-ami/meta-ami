FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += " \
	file://CVE-2025-57052.patch \
	file://0001-CVE-2026-29036.patch \
	"
