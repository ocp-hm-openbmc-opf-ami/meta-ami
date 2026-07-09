FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PROJECT_SRC_DIR := "${THISDIR}/${PN}"

SRC_URI += " \
            file://oauth/;subdir=git/ \
            file://0001-added-IPV6-suppport-to-library.patch \
	    file://0002-Authenticate-to-quit-on-state-machine.patch \
	    file://0110-Coverity-Fix.patch \
	    file://0004-Added-Coverity-Fix.patch \
	    file://0111-OAuth-Support-For-SMTP.patch \
           "
