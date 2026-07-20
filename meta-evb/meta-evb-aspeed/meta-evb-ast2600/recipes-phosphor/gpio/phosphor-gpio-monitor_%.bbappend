FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://phosphor-multi-gpio-monitor.json \
           "

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

