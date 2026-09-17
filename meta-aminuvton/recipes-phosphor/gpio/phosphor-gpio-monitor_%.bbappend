FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://phosphor-multi-gpio-monitor.json \
            file://gpi133-falling.service \
           "

FILES:${PN}-monitor:append = " ${systemd_system_unitdir}/gpi133-falling.service"

do_install:append(){
    install -D ${UNPACKDIR}/phosphor-multi-gpio-monitor.json ${D}${datadir}/phosphor-gpio-monitor/phosphor-multi-gpio-monitor.json
    install -D -m 0644 ${UNPACKDIR}/gpi133-falling.service ${D}${systemd_system_unitdir}/gpi133-falling.service
}
