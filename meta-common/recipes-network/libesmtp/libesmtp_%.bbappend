FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PROJECT_SRC_DIR := "${THISDIR}/${PN}"

SRC_URI += " \
            file://0001-Added-IPV6-suppport-to-library.patch \
           "
