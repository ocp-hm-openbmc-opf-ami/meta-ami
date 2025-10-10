FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += " \
	file://CVE-2023-42364-CVE-2023-42365.patch \
	file://0001-CVE-2023-42363.patch \
	file://enable_timeout.cfg \
	"
