FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
# Todo: Commented out the patch to avoid build failure
#           file://CVE-2022-48174.patch
#           file://CVE-2023-42363.patch 
#           file://CVE-2023-42366.patch
SRC_URI += " \
           file://disable.cfg \
           file://enable.cfg \
		"

SRC_URI += "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'allow-root-login','file://dev-only.cfg','',d)}"
