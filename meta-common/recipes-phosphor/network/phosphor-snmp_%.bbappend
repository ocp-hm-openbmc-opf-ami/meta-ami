FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
             file://0001-snmp-phosphor-ami-functionality.patch \
             file://0002-MemoryLeakIssueAddressing.patch \
	     file://0070-fix-for-OOB-error.patch \
	     file://0080-Coverity-Fix.patch \
           "
