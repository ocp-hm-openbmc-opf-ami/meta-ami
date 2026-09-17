FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
     		file://0001-CVE-2026-47104.patch \
		"

