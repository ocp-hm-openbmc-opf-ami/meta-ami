FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "\
	   file://0007-Change-Privilege-to-system-interface.patch \
	   file://0008-fix-sdr-count-issue.patch \
           file://0009-Removed-SetSelTime-ipmi-Handler.patch \
           "

