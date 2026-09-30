FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "\
		file://0001-Coverity_fixes.patch \
                file://0002-Fix-High-Coverity.patch \
           "
SRC_URI += "file://CVE-2026-46433.patch"
