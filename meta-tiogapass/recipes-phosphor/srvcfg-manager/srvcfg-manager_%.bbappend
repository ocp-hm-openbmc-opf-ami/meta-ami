FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://0001-srvcfg-handle-socket-services-and-update-errors.patch"