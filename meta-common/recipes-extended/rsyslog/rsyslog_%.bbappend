FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " file://hostconsole.conf \
	     file://extlog.conf \
	     file://rsyslog-override.conf \
	     file://rsyslog.logrotate \
	     file://syslog.conf \
	     file://rsyslog.conf \
	   "

FILES:${PN} += "${systemd_system_unitdir}/rsyslog.service.d/rsyslog-override.conf"

PACKAGECONFIG:append = " imjournal openssl"

do_install:append() {
        install -d ${D}${systemd_system_unitdir}/rsyslog.service.d
        install -m 0644 ${WORKDIR}/rsyslog-override.conf \
                        ${D}${systemd_system_unitdir}/rsyslog.service.d/rsyslog-override.conf
        install -m 0755 ${WORKDIR}/hostconsole.conf ${D}${sysconfdir}/rsyslog.d/hostconsole.conf
	install -m 0755 ${WORKDIR}/extlog.conf ${D}${sysconfdir}/rsyslog.d/extlog.conf
        install -m 0755 ${WORKDIR}/syslog.conf ${D}${sysconfdir}/rsyslog.d/syslog.conf
        install -m 0755 ${WORKDIR}/rsyslog.conf ${D}${sysconfdir}/rsyslog.conf
}
