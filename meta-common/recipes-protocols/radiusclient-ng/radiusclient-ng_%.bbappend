# radiusclient-ng_%.bbappend

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Override the base recipe completely
SRC_URI = "git://github.com/FreeRADIUS/freeradius-client.git;branch=master;protocol=https"

SRC_URI += " \
    file://pam_helper.h;subdir=git/include/ \
    file://Encryption.h;subdir=git/include/ \
    file://0284-AMI-Unified-Update.patch \
    file://0285-Fix-For-LF-Sync-Build-Issue.patch \
    "

SRCREV = "c7d94ca0b59f8f618fddd8a73e0876bdbc441dc8"

# Override version
PV = "1.1.8+git${SRCPV}"

# Override source directory
S = "${WORKDIR}/git"

# Override license
LIC_FILES_CHKSUM = "file://COPYRIGHT;md5=2e20d3d71aae8236447afae723235785"

DEPENDS += "libpam nss-pam-ldapd nss-pam-radiusd openssl"
RDEPENDS:${PN} += "libpam nss-pam-ldapd nss-pam-radiusd"

inherit autotools pkgconfig

EXTRA_OECONF += "--disable-static"
EXTRA_OECONF += "ac_cv_func_strlcpy=no"

LDFLAGS += "-lpam -lssl -lcrypto"

do_compile:append() {
    ${CXX} ${LDFLAGS} -shared -o ${S}/src/pam_radius.so ${S}/src/radiusclient.o \
        -L ${S}/lib/.libs -lfreeradius-client
}

do_install:append() {
    install -d ${D}/usr/lib/security/
    install -m 0755 ${S}/src/pam_radius.so ${D}/usr/lib/security/pam_radius.so
}

FILES:${PN} += "/usr/lib/security/pam_radius.so"
