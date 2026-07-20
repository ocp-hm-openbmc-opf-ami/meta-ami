FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += " \
	file://enable_timeout.cfg \
	file://CVE-2026-29004.patch \
	file://CVE-2026-26158.patch \
	"
# Recreate patches if needed,
#	file://CVE-2023-42364-CVE-2023-42365.patch 
#	file://0001-CVE-2023-42363.patch 
