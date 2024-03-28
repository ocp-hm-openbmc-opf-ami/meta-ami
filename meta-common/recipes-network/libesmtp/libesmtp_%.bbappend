FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PROJECT_SRC_DIR := "${THISDIR}/${PN}"

SRC_URI += " \
            file://0001-added-IPV6-suppport-to-library.patch \
	    file://0002-Authenticate-to-quit-on-state-machine.patch \
           "
