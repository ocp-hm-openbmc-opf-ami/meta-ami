FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# for s997 (7-segment display advance service depends on numctl)
SRC_URI:append:s997 = " file://gpi133-falling.service file://phosphor-multi-gpio-monitor-s997.json"

FILES:${PN}-monitor:append:s997 = " ${systemd_system_unitdir}/gpi133-falling.service"

# for s997
do_install:append:s997(){
    install -D -m 0644 ${UNPACKDIR}/gpi133-falling.service ${D}${systemd_system_unitdir}/gpi133-falling.service
    install -D ${UNPACKDIR}/phosphor-multi-gpio-monitor-s997.json ${D}${datadir}/phosphor-gpio-monitor/phosphor-multi-gpio-monitor.json
}
