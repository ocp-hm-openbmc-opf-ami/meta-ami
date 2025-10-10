FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
     file://CVE-2025-7545.patch \
     file://CVE-2025-7546.patch \
     file://CVE-2025-5245.patch \
"
