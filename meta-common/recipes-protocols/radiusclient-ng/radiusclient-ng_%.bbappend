FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
inherit autotools
DEPENDS += "libpam nss-pam-ldapd nss-pam-radiusd"
REPENDS += "libpam nss-pam-ldapd nss-pam-radiusd"
do_compile:append() {
    ${CXX} ${LDFLAGS} -shared -o ${S}/src/pam_radius.so ${S}/src/radiusclient.o -L ./lib/.libs/ -l radiusclient-ng
}

SRC_URI += " \
    file://pam_helper.h;subdir=radiusclient-ng-0.5.6/include/  \
    file://Encryption.h;subdir=radiusclient-ng-0.5.6/include/  \
    file://0003-amiFunctionality.patch  \
    file://0004-Added-Radius-In-Pamorder.patch  \
    file://0004-CVE-2024-3596-Fix-For-Blast-Radius.patch  \
    file://0006-RADIUS-Auth-Init-Info.patch  \
    file://0007-Coverity-Fix.patch  \
    file://0008-Encrypt-and-Decrypt-the-password.patch \
    file://0009-Fix-For-Radius-Decryption-Failed.patch \
    "

LDFLAGS += "-lpam -lssl -lcrypto"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_PACKAGE_STRIP = "1"
INHIBIT_SYSROOT_STRIP = "1"

do_install:append() {
    install -d ${D}/usr/lib/security/
    install -m 0755 ${S}/src/pam_radius.so ${D}/usr/lib/security/pam_radius.so
}
FILES:${PN}  += "/usr/lib/security/pam_radius.so"
