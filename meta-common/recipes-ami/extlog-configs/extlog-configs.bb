SUMMARY = "AMI Extlog support implementation"
DESCRIPTION = "AMI Extlog support implementing ..."
LICENSE = "CLOSED"
# Modify these as desired

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://src/main.cpp \
	   file://include/main.hpp \
	   file://configs/LogIndividualCmds.json \
	   file://configs/extlogconfig.json \
	   file://meson.build \
	   file://service/xyz.openbmc_project.Extlog.ExtlogConfig.service"

S = "${UNPACKDIR}"

DBUS_SERVICE:${PN} += "xyz.openbmc_project.Extlog.ExtlogConfig.service"

DEPENDS = "systemd"
DEPENDS += "nlohmann-json"
DEPENDS += "boost"
DEPENDS += "sdbusplus"
DEPENDS += "sdeventplus"
DEPENDS += "phosphor-dbus-interfaces"
DEPENDS += "phosphor-logging"
DBUS_PACKAGES = "${PN}"

inherit pkgconfig systemd meson
inherit obmc-phosphor-dbus-service

do_install:append() {
	
	install -d ${D}${systemd_system_unitdir}/
	install -m 0644 ${UNPACKDIR}/service/xyz.openbmc_project.Extlog.ExtlogConfig.service ${D}${systemd_system_unitdir}/

	install -d ${D}${sysconfdir_native}/extlog-configs/
    	install -m 0744 ${UNPACKDIR}/configs/extlogconfig.json ${D}${sysconfdir_native}/extlog-configs/
    	install -m 0744 ${UNPACKDIR}/configs/LogIndividualCmds.json ${D}${sysconfdir_native}/extlog-configs/
}

FILES:${PN}  += "${systemd_system_unitdir}/xyz.openbmc_project.Extlog.ExtlogConfig.service"
