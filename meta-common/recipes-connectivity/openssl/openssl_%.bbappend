FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OECONF:append = "${@bb.utils.contains('OPENSSL_FIPS_SUPPORT', 'enabled', ' enable-fips enable-legacy ','', d)}"

# Make openssl-ossl-module-fips provide the old fips-openssl package name for compatibility
RPROVIDES:${PN}-ossl-module-fips += "fips-openssl"

do_install:append() {
   if ${@bb.utils.contains('OPENSSL_FIPS_SUPPORT','enabled','true','false',d)}; then
        install -m755 ${B}/providers/fips.so ${D}${libdir}/ossl-modules
        if [ -f ${B}/providers/legacy.so ]; then
           install -m755 ${B}/providers/legacy.so ${D}${libdir}/ossl-modules
        fi
        install -d ${D}${sysconfdir}/default/
        cp ${D}${libdir}/ssl-3/openssl.cnf ${D}${sysconfdir}/default/
    fi

}
