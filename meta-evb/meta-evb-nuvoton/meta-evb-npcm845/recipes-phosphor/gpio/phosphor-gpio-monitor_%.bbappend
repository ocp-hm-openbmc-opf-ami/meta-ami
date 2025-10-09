FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://0001-Added-Support-event-multi-targets-and-GPIO-mask-feat.patch \
            file://0002-Added-support-for-Multi-Gpio-Monitor-json-file.patch \
           "

FILES:${PN}-monitor = "${bindir}/phosphor-gpio-monitor"
FILES:${PN}-monitor = "${bindir}/phosphor-multi-gpio-monitor"
FILES:${PN}-monitor = "${bindir}/phosphor-gpio-util"
FILES:${PN}-monitor = "${nonarch_base_libdir}/udev/rules.d/99-gpio-keys.rules"
FILES:${PN}-presence = "${bindir}/phosphor-gpio-presence"
FILES:${PN}-presence = "${bindir}/phosphor-multi-gpio-presence"
FILES:${PN}-presence = "${datadir}/${PN}/phosphor-multi-gpio-presence.json"

do_install:append(){
    install -d ${D}/etc/systemd/system/multi-user.target.wants/
    ln -s ${systemd_system_unitdir}/phosphor-multi-gpio-monitor.service ${D}/etc/systemd/system/multi-user.target.wants/phosphor-multi-gpio-monitor.service
           ln -s ${systemd_system_unitdir}/phosphor-gpio-presence@.service ${D}/etc/systemd/system/multi-user.target.wants/phosphor-gpio-presence@.service
}
