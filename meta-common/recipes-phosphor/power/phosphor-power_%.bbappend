FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit systemd

SRC_URI += " \
           file://psu.json \
	   file://phos-psu-monitor.service \
           file://0001-phosphor-power-psu-monitor.patch \
           "

PACKAGECONFIG:append = " monitor"
PACKAGECONFIG:append = " monitor-ng"

do_install:append(){

    install -D ${WORKDIR}/psu.json ${D}${datadir}/phosphor-power/psu.json
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 -D ${WORKDIR}/phos-psu-monitor.service ${D}${systemd_system_unitdir}/phos-psu-monitor.service    
    install -d ${D}/etc/systemd/system/multi-user.target.wants/
    ln      -s ${systemd_system_unitdir}/phos-psu-monitor.service ${D}/etc/systemd/system/multi-user.target.wants/phos-psu-monitor.service
}

SYSTEMD_SERVICE:${PN} = "phos-psu-monitor.service"

FILES:${PN}-psu-monitor = "${bindir}/phosphor-psu-monitor"
FILES:${PN}-psu-monitor = "${datadir}/phosphor-psu-monitor"
FILES:${PN} += "${systemd_system_unitdir}/phos-psu-monitor.service"
FILES:${PN} += "${datadir}/phosphor-power/psu.json"

