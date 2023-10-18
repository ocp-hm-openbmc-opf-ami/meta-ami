FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PROJECT_SRC_DIR := "${THISDIR}/${PN}"

SRC_URI += "file://0001-EMail-Update-the-install-location-for-systemd-servic.patch \
        "
