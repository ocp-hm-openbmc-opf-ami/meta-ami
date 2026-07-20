FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OECONF:append = "${@bb.utils.contains('OPENSSL_FIPS_SUPPORT', 'enabled', ' enable-fips enable-legacy ','', d)}"

# Make openssl-ossl-module-fips provide the old fips-openssl package name for compatibility
RPROVIDES:${PN}-ossl-module-fips += "fips-openssl"

do_install:append() {
   if ${@bb.utils.contains('OPENSSL_FIPS_SUPPORT','enabled','true','false',d)}; then
        install -m755 ${B}/providers/fips.so ${D}${libdir}/ossl-modules
        install -m755 ${B}/providers/legacy.so ${D}${libdir}/ossl-modules
        install -d ${D}${sysconfdir}/default/
        cp ${D}${libdir}/ssl-3/openssl.cnf ${D}${sysconfdir}/default/
    fi

}

SRC_URI += " \
	file://CVE-2025-9230.patch \
	file://CVE-2025-9231.patch \
	file://CVE-2025-9232.patch \
	file://CVE-2025-15467.patch \
	file://CVE-2025-11187.patch \
	file://CVE-2025-69419.patch \
	file://CVE-2025-69420.patch \
	file://CVE-2025-69421.patch \
        file://CVE-2025-68160.patch \
	file://CVE-2025-69418.patch \
	file://CVE-2026-22795.patch \
	file://CVE-2025-15468.patch \
	file://CVE-2025-15469.patch \
        file://CVE-2025-66199.patch \
        file://CVE-2026-2673.patch \
        file://CVE-2026-31790.patch \
        file://CVE-2026-28390.patch \
        file://CVE-2026-31789.patch \
        file://CVE-2026-28387.patch \
        file://CVE-2026-28388.patch \
        file://CVE-2026-28389.patch \
	"
