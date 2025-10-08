SUMMARY = "Secure Socket Layer"
DESCRIPTION = "Secure Socket Layer (SSL) binary and related cryptographic tools."
HOMEPAGE = "http://www.openssl.org/"
BUGTRACKER = "http://www.openssl.org/news/vulnerabilities.html"
SECTION = "libs/network"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=c75985e733726beaba57bc5253e96d04"
inherit perlnative
SRC_URI = "http://www.openssl.org/source/openssl-${PV}.tar.gz \
           file://run-ptest \
           file://0001-buildinfo-strip-sysroot-and-debug-prefix-map-from-co.patch \
           file://afalg.patch \
           file://0001-Configure-do-not-tweak-mips-cflags.patch \
           "
S = "${WORKDIR}/openssl-${PV}"

DISABLE_STATIC = ""
SRC_URI[sha256sum] = "eb1ab04781474360f77c318ab89d8c5a03abc38e63d65a603cabbf1b00a1dc90"

B = "${WORKDIR}/build"
do_configure[cleandirs] = "${B}"

# General config settings.
EXTRA_OECONF:append:class-target = " shared no-hw no-err no-psk no-srp  no-ssl2 no-ssl3 \
    no-rmd160 \
    no-whirlpool \
    no-rc2 \
    no-rc4 \
    no-bf \
    no-cast \
    no-gost \
    no-legacy \
    enable-fips \
"
FILES:${PN} =+ "${libdir}/ossl-modules/fips.so"

do_configure:append() {
    oe_runmake depend
}

# We don't want to depend on perl in our image
RDEPENDS:${PN}-bin:remove = "perl"

FILES:${PN}-misc:append = " ${bindir}/c_rehash"



# This allows disabling deprecated or undesirable crypto algorithms.
# The default is to trust upstream choices.
DEPRECATED_CRYPTO_FLAGS ?= ""

do_configure () {
	# When we upgrade glibc but not uninative we see obtuse failures in openssl. Make
	# the issue really clear that perl isn't functional due to symbol mismatch issues.
	cat <<- EOF > ${WORKDIR}/perltest
	#!/usr/bin/env perl
	use POSIX;
	EOF
	chmod a+x ${WORKDIR}/perltest
	${WORKDIR}/perltest

	os=${HOST_OS}
	case $os in
	linux-gnueabi |\
	linux-gnuspe |\
	linux-musleabi |\
	linux-muslspe |\
	linux-musl )
		os=linux
		;;
	*)
		;;
	esac
	target="$os-${HOST_ARCH}"
	case $target in
	linux-arm*)
		target=linux-armv4
		;;
	linux-aarch64*)
		target=linux-aarch64
		;;
	esac

	useprefix=${prefix}
	if [ "x$useprefix" = "x" ]; then
		useprefix=/
	fi
	# WARNING: do not set compiler/linker flags (-I/-D etc.) in EXTRA_OECONF, as they will fully replace the
	# environment variables set by bitbake. Adjust the environment variables instead.
	HASHBANGPERL="/usr/bin/env perl" PERL=perl PERL5LIB="${S}/external/perl/Text-Template-1.46/lib/" \
	perl ${S}/Configure ${EXTRA_OECONF} ${PACKAGECONFIG_CONFARGS} ${DEPRECATED_CRYPTO_FLAGS} --prefix=$useprefix --openssldir=${libdir}/ssl-3 --libdir=${libdir} $target
	perl ${B}/configdata.pm --dump
}

do_install () {
	oe_runmake DESTDIR="${D}" install_fips
        rm -r ${D}${libdir}/ssl-3
}
