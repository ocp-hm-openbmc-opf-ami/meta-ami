FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " file://hostconsole.conf \
	     file://rsyslog-override.conf \
	     file://rsyslog.logrotate \
	   "

FILES:${PN} += "${systemd_system_unitdir}/rsyslog.service.d/rsyslog-override.conf"

PACKAGECONFIG:append = " imjournal"

do_install:append() {
        install -d ${D}${systemd_system_unitdir}/rsyslog.service.d
        install -m 0644 ${WORKDIR}/rsyslog-override.conf \
                        ${D}${systemd_system_unitdir}/rsyslog.service.d/rsyslog-override.conf
        install -m 0755 ${WORKDIR}/hostconsole.conf ${D}${sysconfdir}/rsyslog.d/hostconsole.conf
}
