FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://net-snmp-create-v3-user \
    file://0001-Added-changes-to-support-system-lock-mode-for-set-SN.patch \
    "

do_install:append(){

    install -m 0644 ${WORKDIR}/snmpd.conf ${D}/etc/snmp/snmpd.conf
    install -m 0744 ${WORKDIR}/net-snmp-create-v3-user ${D}${bindir}/AMI-snmp-create-v3-user
}
FILES_${PN}-dev += ""
FILES_${PN} += "${bindir}/AMI-snmp-create-v3-user"

LDFLAGS += "-lsystemd"

