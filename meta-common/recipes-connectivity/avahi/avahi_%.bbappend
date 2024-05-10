FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
		file://0001-Postpone-Avahi-Daemon-Initializtion-Order.patch \
                file://CVE-2023-1981.patch \
                file://CVE-2023-38469.patch \
                file://CVE-2023-38470.patch \
                file://CVE-2023-38471.patch \
                file://CVE-2023-38472.patch \
                file://CVE-2023-38473.patch \
		"

