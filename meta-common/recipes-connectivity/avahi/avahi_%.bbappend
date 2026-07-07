FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
		file://0001-Postpone-Avahi-Daemon-Initializtion-Order.patch \
		file://CVE-2024-52615.patch \
		file://CVE-2024-52616.patch \
		file://CVE-2026-34933.patch \
		"

