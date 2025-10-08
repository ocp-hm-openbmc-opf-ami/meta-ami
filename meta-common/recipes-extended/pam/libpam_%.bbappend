FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://pam.d/common-auth \
            file://faillock.conf \
            file://pam.d/common-auth \
            file://pam.d/common-account \
	    file://0004-Deny-Disabled-User.patch \
	    file://0005-Internal-Auth-Init-Info.patch \
           "
