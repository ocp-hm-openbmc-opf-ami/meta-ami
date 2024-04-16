SUMMARY = "AMI service license validation implementation"
DESCRIPTION = "AMI service license validation implementing ..."
LICENSE = "CLOSED"
# Modify these as desired

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/license-control.git;protocol=https;branch=main"
SRCREV = "a0320f37b52d1a255c47a7e4456a0233ba2c1900"

S = "${WORKDIR}/git"
PV = "1.0+git${SRCPV}"

DBUS_SERVICE:${PN} += "xyz.openbmc_project.License.LicenseControl.service"

DEPENDS = "systemd"
DEPENDS += "nlohmann-json"
RDEPENDS:${PN} += "libsystemd bash"
DEPENDS += "boost"
DEPENDS += "sdbusplus"
DEPENDS += "sdeventplus"
DEPENDS += "phosphor-dbus-interfaces"
DEPENDS += "phosphor-logging"
DEPENDS += "openssl"
DBUS_PACKAGES = "${PN}"

inherit pkgconfig systemd meson
inherit obmc-phosphor-dbus-service

do_install:append() {
	
	install -d ${D}${systemd_system_unitdir}/
	install -m 0644 ${S}/service_files/xyz.openbmc_project.License.LicenseControl.service ${D}${systemd_system_unitdir}/

	install -d ${D}${sysconfdir_native}/license-control/
    	install -m 0744 ${S}/conf/license.json ${D}${sysconfdir_native}/license-control/
	install -m 0744 ${S}/conf/token ${D}${sysconfdir_native}/license-control/
}

FILES:${PN}  += "${systemd_system_unitdir}/xyz.openbmc_project.License.LicenseControl.service"
