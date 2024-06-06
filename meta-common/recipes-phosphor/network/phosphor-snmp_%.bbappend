FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " file://0001-ipv6-fix.patch \
             file://0002-snmp-v1-support.patch \
             file://0003-snmp-v3-support.patch \
             file://0004-snmp-algorithm-support.patch \
             file://0005-Added-to-change-for-enable-disable-SNMPTrap.patch \
             file://0006-Added-changes-for-SNMPTrap-Bind-variables.patch \
             file://0007-Added-changes-for-SNMP-Address-Port-validation.patch \
             file://0008-Added-Changes-For-User-Validation-While-Sending-Trap.patch \
             file://0009-SNMPTrap-support-to-Change-Community-string-and-enab.patch \
             file://0010-Fixed-error-while-using-snmp_notification-header-fil.patch \
           "
