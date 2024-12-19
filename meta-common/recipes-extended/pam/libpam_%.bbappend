FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://pam.d/common-auth \
            file://faillock.conf \
            file://pam.d/common-auth \
            file://pam.d/common-account \
           "
