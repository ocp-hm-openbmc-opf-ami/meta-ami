FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
 
SRC_URI += " \
	file://CVE-2025-14104.patch \
	file://CVE-2026-27456.patch \
	file://CVE-2026-53612.patch \
	file://CVE-2026-53613.patch \
	file://CVE-2026-53614.patch \
"
