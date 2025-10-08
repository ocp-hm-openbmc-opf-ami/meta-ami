FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://0229-Adding-AMI-Functionality.patch \
    file://0212-Coverity-Fix.patch \
    "
libname = "pam_google_authenticator.so"
securitylibdir = "/usr/lib/security"

FILES:${PN} += "${securitylibdir}/${libname}"

