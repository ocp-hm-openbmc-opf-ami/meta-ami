FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://net-snmp-create-v3-user \
    file://0001-SNMP-lock-mode.patch \
    "

do_install:append(){

    install -m 0644 ${WORKDIR}/snmpd.conf ${D}/etc/snmp/snmpd.conf
    touch ${D}/usr/share/snmp/snmpd.conf
    chmod 0777 ${D}/usr/share/snmp/snmpd.conf
    install -m 0777 ${WORKDIR}/net-snmp-create-v3-user ${D}${bindir}/AMI-snmp-create-v3-user
}
FILES_${PN}-dev += ""
FILES_${PN} += "${bindir}/AMI-snmp-create-v3-user"

LDFLAGS += "-lsystemd"

