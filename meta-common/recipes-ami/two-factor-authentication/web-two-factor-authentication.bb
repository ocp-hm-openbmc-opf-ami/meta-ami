SUMMARY = "AMI service license validation implementation"
DESCRIPTION = "AMI service license validation implementing ..."
LICENSE = "CLOSED"
# Modify these as desired

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/two-factor-authentication.git;protocol=https;branch=main"
SRCREV = "3ca95c8b7b5ce7783d833c74c7253ade823cd9f8"


S = "${WORKDIR}/git"
PV = "1.0+git${SRCPV}"

DBUS_SERVICE:${PN} += "xyz.openbmc_project.TwoFactorAuthentication.WebTwoFactorAuthentication.service"

DEPENDS = "systemd"
DEPENDS += "nlohmann-json"
RDEPENDS:${PN} += "libsystemd bash"
DEPENDS += "boost"
DEPENDS += "sdbusplus"
DEPENDS += "sdeventplus"
DEPENDS += "phosphor-dbus-interfaces"
DEPENDS += "phosphor-logging"
DEPENDS += "google-authenticator-libpam"

DBUS_PACKAGES = "${PN}"

inherit pkgconfig systemd meson
inherit obmc-phosphor-dbus-service

do_install() {
         
          install -d ${D}${bindir}
          install -d ${D}${systemd_system_unitdir}/
          install -d ${D}/usr/lib/security
          install -d ${D}/etc/pam.d/
          install -m 0755 ${WORKDIR}/build/WebTwoFactorAuthentication ${D}${bindir}
          install -m 0755 ${S}/xyz.openbmc_project.TwoFactorAuthentication.WebTwoFactorAuthentication.service ${D}${systemd_system_unitdir}/
          install -m 0755 ${S}/pam_google_authenticator.so ${D}/usr/lib/security/
          install -m 0755 ${S}/tfa ${D}/etc/pam.d/
	
}

FILES:${PN}  += "${bindir}"
FILES:${PN}  += "/etc/pam.d/tfa"
FILES:${PN}  += "/usr/lib/security/pam_google_authenticator.so"
FILES:${PN}  += "${systemd_system_unitdir}/xyz.openbmc_project.TwoFactorAuthentication.WebTwoFactorAuthentication.service"
