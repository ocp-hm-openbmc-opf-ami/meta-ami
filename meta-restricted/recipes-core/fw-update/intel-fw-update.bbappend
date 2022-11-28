# Restricted override intel-fw-update script

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
PROJECT_SRC_DIR := "${THISDIR}/files"

SRC_URI += "file://fwupd-restricted.sh"

do_install:append() {
        install -m 0755 ${WORKDIR}/fwupd-restricted.sh ${D}${bindir}/fwupd.sh
}

