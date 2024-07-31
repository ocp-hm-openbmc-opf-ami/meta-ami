FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://taskset.cfg "
SRC_URI:append = " file://mkfs.cfg "
SRC_URI:append = " file://dd.cfg "
SRC_URI:append = " file://mpstat.cfg "
SRC_URI:append = " file://crc32.cfg "
SRC_URI:append = " file://lsusb.cfg "
