FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://pam.d/common-auth \
            file://faillock.conf \
           "
#SRC_URI += " file://CVE-2024-22365.patch "

