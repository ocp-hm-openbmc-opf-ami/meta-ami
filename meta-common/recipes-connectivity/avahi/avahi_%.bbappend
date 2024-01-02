FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
		file://0001-Postpone-Avahi-Daemon-Initializtion-Order.patch \
		"

