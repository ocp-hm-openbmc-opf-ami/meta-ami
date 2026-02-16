FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
 
SRC_URI += " \
            file://CVE-2024-4032.patch \
            file://CVE-2024-7592.patch \
            file://CVE-2024-6232.patch \
            file://CVE-2024-8088.patch \
            file://CVE-2024-12254.patch \
            file://CVE-2025-4517.patch \
            file://CVE-2025-8194.patch \
	    file://CVE-2025-6069.patch \
           "
