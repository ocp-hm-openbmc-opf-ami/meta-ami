FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI += " file://0001-ipv6-fix.patch \
             file://0002-snmp-v1-support.patch \
             file://0003-snmp-v3-support.patch \
             file://0004-snmp-algorithm-support.patch \
           "
