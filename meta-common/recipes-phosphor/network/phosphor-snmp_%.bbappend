FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_configure:prepend() {
    install -m 0644 ${WORKDIR}/Encryption.cpp ${S}/
    install -m 0644 ${WORKDIR}/Encryption.hpp ${S}/
}
SRC_URI += " \
             file://0001-snmp-phosphor-ami-functionality.patch \
             file://0002-MemoryLeakIssueAddressing.patch \
	     file://0070-fix-for-OOB-error.patch \
	     file://0080-Coverity-Fix.patch \
	     file://0072-Decrypt_SNMPv3_Traps.patch \
	     file://0006-Added-Community-String-Validation.patch \
	     file://Encryption.hpp \
	     file://Encryption.cpp \
	     file://0074-Decryption-of-SNMP-User-Password.patch \
	     file://0075-ReducedTrapSentTimeOnFailureState.patch \
           "
# Inline edit of the installed systemd unit
do_install:append() {
    # Only add if not already present
    grep -q 'xyz.openbmc_project.Snmp.Conf.service' \
        ${D}${systemd_system_unitdir}/xyz.openbmc_project.Network.SNMP.service || \
    sed -i '/^Description=Phosphor SNMP conf Manager/a Requires=xyz.openbmc_project.Snmp.Conf.service\nAfter=xyz.openbmc_project.Snmp.Conf.service' \
        ${D}${systemd_system_unitdir}/xyz.openbmc_project.Network.SNMP.service
}
