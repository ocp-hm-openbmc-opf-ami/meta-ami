FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit systemd

SRC_URI += " \
            file://psu.json \
            file://psu-detction.sh \
            file://phosphor-psu-monitor.service \
            file://0001-recreated-phosphor-power-psu-monitor.patch \
            file://0002-recreated-Coverity-fix.patch \
            file://0003-Multi-PSU-Runtime-support.patch \
           file://0004-High-Coverity-fixes.patch \
           "
SRCREV = "6c9e3cb88a909a514df76088ff869d413b33ea19"

PACKAGECONFIG:append = " monitor"
PACKAGECONFIG:append = " monitor-ng"


do_install:append(){

     install -D ${UNPACKDIR}/psu.json ${D}${datadir}/phosphor-power/psu.json
     install -d ${D}${systemd_system_unitdir}
     install -m 0744 ${UNPACKDIR}/psu-detction.sh ${D}/${bindir}/psu-detction.sh
     install -m 0644 -D ${UNPACKDIR}/phosphor-psu-monitor.service ${D}${systemd_system_unitdir}/phosphor-psu-monitor.service
     install -d ${D}/etc/systemd/system/multi-user.target.wants/
     ln      -s ${systemd_system_unitdir}/phosphor-psu-monitor.service ${D}/etc/systemd/system/multi-user.target.wants/phosphor-psu-monitor.service
}

SYSTEMD_SERVICE:${PN} = "phosphor-psu-monitor.service"

FILES:${PN}-psu-monitor = "${bindir}/phosphor-psu-monitor"
FILES:${PN}-psu-monitor = "${datadir}/phosphor-psu-monitor"
FILES:${PN} += "${systemd_system_unitdir}/phosphor-psu-monitor.service"
FILES:${PN} += "${datadir}/phosphor-power/psu.json"
FILES:${PN}:append = " ${bindir}/psu-detction.sh"
FILES:${PN} += "${systemd_system_unitdir}/psu-detction.sh"

