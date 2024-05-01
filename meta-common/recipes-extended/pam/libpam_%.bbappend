FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://faillock.conf \
            file://CVE-2024-22365.patch \
           "
