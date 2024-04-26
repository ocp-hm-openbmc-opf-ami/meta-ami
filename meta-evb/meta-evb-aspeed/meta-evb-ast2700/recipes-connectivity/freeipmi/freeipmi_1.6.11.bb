DESCRIPTION = "FreeIPMI provides in-band and out-of-band IPMI software based on the IPMI v1.5/2.0 specification."
HOMEPAGE = "https://www.gnu.org/software/freeipmi/"
SUMMARY = "IPMI in-band/out-of-band utility"

PR = "r1"

LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://COPYING.ipmi-fru;md5=d32239bcb673463ab874e80d47fae504 \
                    file://COPYING.ipmimonitoring;md5=d32239bcb673463ab874e80d47fae504 \
                    file://COPYING.sunbmc;md5=c03f21cd76ff5caba6b890d1213cbfbb \
                    file://COPYING.ipmidetect;md5=d32239bcb673463ab874e80d47fae504 \
                    file://COPYING.pstdout;md5=d32239bcb673463ab874e80d47fae504 \
                    file://COPYING.ZRESEARCH;md5=d32239bcb673463ab874e80d47fae504 \
                    file://COPYING.ipmi-dcmi;md5=d32239bcb673463ab874e80d47fae504 \
                    file://COPYING.bmc-watchdog;md5=d32239bcb673463ab874e80d47fae504 \
                    file://COPYING.ipmipower;md5=d32239bcb673463ab874e80d47fae504 \
                    file://COPYING.ipmiseld;md5=d32239bcb673463ab874e80d47fae504 \
                    file://COPYING;md5=d32239bcb673463ab874e80d47fae504 \
                    file://COPYING.ipmiping;md5=d32239bcb673463ab874e80d47fae504 \
                    file://COPYING.ipmiconsole;md5=d32239bcb673463ab874e80d47fae504"

SRC_URI = "https://ftp.gnu.org/gnu/freeipmi/freeipmi-${PV}.tar.gz"
SRC_URI[sha256sum] = "65fbd6910fc010457748695414f27c5755b4e8d75734221221f3858c6230a897"

inherit autotools pkgconfig

EXTRA_OECONF = " --without-encryption \
                 --without-random-device \
                 --disable-init-scripts \
                 --with-dont-check-for-root \
                 --enable-rawdumps \
               "

PACKAGES =+ " \
    ${PN}-ipmi-raw \
    ${PN}-other \
    "

FILES:${PN}-ipmi-raw = " ${sbindir}/ipmi-raw "
FILES:${PN}-other = " ${sbindir}/* "
