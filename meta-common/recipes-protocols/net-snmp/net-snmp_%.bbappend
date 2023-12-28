FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append(){

    install -m 0644 ${WORKDIR}/snmpd.conf ${D}/etc/snmp/snmpd.conf
}
