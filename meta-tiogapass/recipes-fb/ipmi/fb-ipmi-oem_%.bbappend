FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://0001-storage-Avoid-duplicate-SDR-handlers.patch"