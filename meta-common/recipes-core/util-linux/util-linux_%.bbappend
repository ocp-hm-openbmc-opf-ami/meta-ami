FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://CVE-2026-76642.patch"
SRC_URI += "file://CVE-2026-78408.patch"
SRC_URI += "file://CVE-2026-78410.patch"
