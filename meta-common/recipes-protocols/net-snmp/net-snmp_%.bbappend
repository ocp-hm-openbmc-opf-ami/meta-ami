FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://net-snmp-create-v3-user \
    file://0001-SNMP-lock-mode.patch \
    file://0002-Fix-for-unclosed-sockets.patch \
    file://CVE-2025-68615.patch \
    "

do_install:append(){

    install -m 0644 ${WORKDIR}/snmpd.conf ${D}/etc/snmp/snmpd.conf
    touch ${D}/usr/share/snmp/snmpd.conf
    chmod 0744 ${D}/usr/share/snmp/snmpd.conf
    install -m 0755 ${WORKDIR}/net-snmp-create-v3-user ${D}${bindir}/AMI-snmp-create-v3-user
    rm -f ${D}${systemd_unitdir}/system/snmptrapd.service || true
    rm -f ${D}${sbindir}/snmptrapd || true
}
FILES_${PN}-dev += ""
FILES_${PN} += "${bindir}/AMI-snmp-create-v3-user"

LDFLAGS += "-lsystemd"

# Prevent expecting the snmptrapd.service unit (we remove it above)
SYSTEMD_SERVICE:${PN}-server-snmptrapd = ""

