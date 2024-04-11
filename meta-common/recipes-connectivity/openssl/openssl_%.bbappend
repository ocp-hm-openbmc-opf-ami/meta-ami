FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"



# EXTRA_OECONF:append = " enable-fips enable-legacy"
# PACKAGES =+ "${PN}-ossl-module-fips"
# FILES:fips = "${libdir}/ossl-modules/fips.so"
# FILES:legacy = "${libdir}/ossl-modules/legacy.so"

# FILES:${PN} =+ "${libdir}/ossl-modules/*"

EXTRA_OECONF:append = "${@bb.utils.contains('OPENSSL_FIPS_SUPPORT', 'enabled', 'enable-fips enable-legacy','', d)}"

PACKAGES =+ "${@bb.utils.contains('OPENSSL_FIPS_SUPPORT', 'enabled', 'enable-fips enable-legacy','', d)}"
FILES:fips = "${@bb.utils.contains('OPENSSL_FIPS_SUPPORT', 'enabled', '${libdir}/ossl-modules/fips.so','', d)}"
FILES:legacy = "${@bb.utils.contains('OPENSSL_FIPS_SUPPORT', 'enabled', '${libdir}/ossl-modules/legacy.so','', d)}"
FILES:${PN} =+ "${@bb.utils.contains('OPENSSL_FIPS_SUPPORT', 'enabled', '${libdir}/ossl-modules/*','', d)}"

do_install:append() {
   if ${@bb.utils.contains('OPENSSL_FIPS_SUPPORT','enabled','true','false',d)}; then
        install -m755 ${B}/providers/fips.so ${D}${libdir}/ossl-modules
        install -m755 ${B}/providers/legacy.so ${D}${libdir}/ossl-modules
        install -d ${D}${sysconfdir}/default/
        cp ${D}${libdir}/ssl-3/openssl.cnf ${D}${sysconfdir}/default/
    fi

}



