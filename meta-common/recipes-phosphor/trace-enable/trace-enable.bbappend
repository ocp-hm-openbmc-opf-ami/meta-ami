FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " file://trace-enable"

SYSTEMD_SERVICE:${PN} = "trace-enable.service"
