FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
 
SRC_URI += " \
            file://CVE-2024-4032.patch \
            file://CVE-2024-7592.patch \
            file://CVE-2024-6232.patch \
           "
