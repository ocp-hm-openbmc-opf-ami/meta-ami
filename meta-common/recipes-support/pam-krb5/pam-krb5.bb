SUMMARY = "PAM module for Kerberos authentication "
DESCRIPTION = " pam-krb5 is a Kerberos PAM module "

LICENSE = "CLOSED"


# Source URI pointing to the GitHub repository
SRC_URI = "git://github.com/rra/pam-krb5.git;branch=main;protocol=https"
SRC_URI += " \
           file://0001-Fix-build-issue-forKerberos-PAM-module.patch \
           "


SRCREV = "54deebe6a6f2ec177ac3669391c424d5ea96a718"  

S = "${WORKDIR}/git"

inherit autotools

DEPENDS += "krb5"


FILES:${PN} += "${libdir}/security/pam_krb5.so"
