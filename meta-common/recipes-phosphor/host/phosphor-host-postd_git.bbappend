FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-Intergrating-SBMR-boot-progress-code-support-to-lpcs.patch"

EXTRA_OEMESON:append = "-Dsystemd-after-service=systemd-modules-load.service "

