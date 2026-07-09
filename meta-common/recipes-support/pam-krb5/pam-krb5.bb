SUMMARY = "PAM module for Kerberos authentication "
DESCRIPTION = " pam-krb5 is a Kerberos PAM module "

LICENSE = "CLOSED"


# Source URI pointing to the GitHub repository
SRC_URI = "git://github.com/rra/pam-krb5.git;branch=main;protocol=https"
# Todo: Commented out the patch to avoid build failure
# SRC_URI += " \
#            file://0001-Fix-build-issue-forKerberos-PAM-module.patch \
#            "


SRCREV = "54deebe6a6f2ec177ac3669391c424d5ea96a718"  

S = "${WORKDIR}/git"

inherit autotools

DEPENDS += "krb5 perl-native"

# The build tries to generate man pages with pod2man and expects a docs/ directory
# in the build directory. Create it before compilation starts.
do_compile:prepend() {
    mkdir -p ${B}/docs
}

FILES:${PN} += "${libdir}/security/pam_krb5.so"
