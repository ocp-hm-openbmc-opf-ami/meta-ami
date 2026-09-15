FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
	file://0001-dbus-sdr-Support-dynamic-sensors.patch \
"

PACKAGECONFIG:append = " dynamic-sensors"

