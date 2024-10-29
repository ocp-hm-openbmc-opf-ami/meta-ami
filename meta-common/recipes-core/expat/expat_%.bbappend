FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += " \
        file://CVE-2024-45492.patch \
        file://CVE-2024-45491.patch \
        file://CVE-2024-45490.patch \
	"
