SUMMARY = "OpenSSL DBUS object"
DESCRIPTION = "OpenSSL DBUS object"
LICENSE = "CLOSED"
DEPENDS += "systemd"
DEPENDS += "sdbusplus ${PYTHON_PN}-sdbus++-native"
DEPENDS += "sdeventplus"
DEPENDS += "phosphor-dbus-interfaces"
DEPENDS += "phosphor-logging"
DEPENDS += "libnl"
DEPENDS += "stdplus"
DEPENDS += "openssl"
RDEPENDS:${PN} = "bash"

S = "${WORKDIR}/git"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.OpenSSL.service"

inherit meson pkgconfig
inherit python3native
inherit systemd

FILES:${PN} += "${datadir}/dbus-1/system.d"

EXTRA_OEMESON:append = "${@bb.utils.contains('OPENSSL_FIPS_SUPPORT', 'enabled', ' -Dsupport-openssl-fips=true ','', d)}"

EXTRA_OEMESON:append = " -Ddefault-enable-openssl-fips=false "

EXTRA_OEMESON:append = " -Dtests=disabled"


SRC_URI += "${@bb.utils.contains('OPENSSL_FIPS_SUPPORT', 'enabled', 'file://openssl_fips_swich.sh','', d)} \
            file://0001-Implement-OpenSSL-Manager-to-Control-OpenSSL-and-its-Functionality.patch \
            file://0002-Change-Conf-File-Location.patch \
            "


do_install:append() {
	if ${@bb.utils.contains('OPENSSL_FIPS_SUPPORT', 'enabled', 'true', 'false', d)}; then
		install -d ${D}/${bindir}
		install -m 0755 ${WORKDIR}/openssl_fips_swich.sh ${D}/${bindir}/
	fi
}
