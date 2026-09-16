FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
	    file://phosphor-multi-gpio-monitor.json \
           "

# for s997 (7-segment display advance service depends on numctl)
SRC_URI:append:s997 = " file://gpi133-falling.service file://phosphor-multi-gpio-monitor-s997.json"

FILES:${PN}-monitor:append:s997 = " ${systemd_system_unitdir}/gpi133-falling.service"

FILES:${PN}-monitor = "${bindir}/phosphor-gpio-monitor"
FILES:${PN}-monitor = "${bindir}/phosphor-multi-gpio-monitor"
FILES:${PN}-monitor = "${bindir}/phosphor-gpio-util"
FILES:${PN}-monitor = "${nonarch_base_libdir}/udev/rules.d/99-gpio-keys.rules"
FILES:${PN}-presence = "${bindir}/phosphor-gpio-presence"
FILES:${PN}-presence = "${bindir}/phosphor-multi-gpio-presence"
FILES:${PN}-presence = "${datadir}/${PN}/phosphor-multi-gpio-presence.json"

do_install:append(){
    install -D ${UNPACKDIR}/phosphor-multi-gpio-monitor.json ${D}${datadir}/phosphor-gpio-monitor/phosphor-multi-gpio-monitor.json
    install -d ${D}/etc/systemd/system/multi-user.target.wants/
    ln -s ${systemd_system_unitdir}/phosphor-multi-gpio-monitor.service ${D}/etc/systemd/system/multi-user.target.wants/phosphor-multi-gpio-monitor.service
           ln -s ${systemd_system_unitdir}/phosphor-gpio-presence@.service ${D}/etc/systemd/system/multi-user.target.wants/phosphor-gpio-presence@.service
}

# for s997
do_install:append:s997(){
    install -D -m 0644 ${UNPACKDIR}/gpi133-falling.service ${D}${systemd_system_unitdir}/gpi133-falling.service
    install -D ${UNPACKDIR}/phosphor-multi-gpio-monitor-s997.json ${D}${datadir}/phosphor-gpio-monitor/phosphor-multi-gpio-monitor.json
}
