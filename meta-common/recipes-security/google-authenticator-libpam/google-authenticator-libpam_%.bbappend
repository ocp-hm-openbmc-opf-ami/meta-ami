FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://0229-Adding-AMI-Functionality.patch \
    "
libname = "pam_google_authenticator.so"
securitylibdir = "/usr/lib/security"

FILES_${PN}-dev += ""
FILES_${PN} = "${securitylibdir}/${libname}"

