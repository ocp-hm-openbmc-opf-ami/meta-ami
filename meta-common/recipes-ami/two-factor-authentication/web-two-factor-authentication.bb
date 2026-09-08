SUMMARY = "AMI service license validation implementation"
DESCRIPTION = "AMI service license validation implementing ..."
LICENSE = "CLOSED"
# Modify these as desired

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/two-factor-authentication.git;protocol=https;branch=integrate-onetree-3.1.1"



SRCREV = "eaf5e522197d196fbd9257c5b29487e579e5f6e5"


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
          install -d ${D}/etc/pam.d/
          install -m 0755 ${B}/WebTwoFactorAuthentication ${D}${bindir}
          install -m 0755 ${S}/xyz.openbmc_project.TwoFactorAuthentication.WebTwoFactorAuthentication.service ${D}${systemd_system_unitdir}/
          install -m 0755 ${S}/tfa ${D}/etc/pam.d/
	
}

FILES:${PN}  += "${bindir}"
FILES:${PN}  += "/etc/pam.d/tfa"
FILES:${PN}  += "${systemd_system_unitdir}/xyz.openbmc_project.TwoFactorAuthentication.WebTwoFactorAuthentication.service"
