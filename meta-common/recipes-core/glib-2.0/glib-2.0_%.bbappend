FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += " \ 
	file://CVE-2024-52533.patch \
	file://CVE-2025-4056.patch \
	file://CVE-2025-4373.patch \
	"
