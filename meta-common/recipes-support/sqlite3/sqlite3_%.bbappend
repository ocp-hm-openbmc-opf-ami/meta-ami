FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += " \
	file://CVE-2025-29087.patch \
	file://CVE-2025-29088.patch \
	file://0001-Resolved-the-undefined-reference-to-Fts5TombstoneArr.patch \
	file://CVE-2025-7709.patch \
	"
