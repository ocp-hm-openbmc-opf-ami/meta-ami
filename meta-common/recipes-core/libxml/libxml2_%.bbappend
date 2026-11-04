FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://CVE-2026-86140.patch"
SRC_URI += "file://CVE-2026-74860.patch"
