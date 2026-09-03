FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SERIAL_DEVICE = "ttyAMA2"

RRECOMMENDS:${PN}:remove = "phosphor-settings-manager"

EXTRA_OEMESON += "-Darm-sbmr=enabled"


RPROVIDES:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'transport-null', '', 'virtual-obmc-host-ipmi-hw', d)}"
PACKAGECONFIG:append = " transport-null"

PACKAGECONFIG:remove = "transport-null"
PACKAGECONFIG[transport-serial] = "-Dtransport-implementation=serial,,,,,transport-null"
PACKAGECONFIG[transport-null] = "-Dtransport-implementation=null,,,,,transport-serial"

FILES:${PN} += " ${systemd_system_unitdir}/serialbridge@.service"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'transport-serial', \
                                               'serialbridge@${SERIAL_DEVICE}.service', \
                                              '', d)}"

PACKAGECONFIG:append = " \
    transport-serial \
"
RPROVIDES:${PN} += "virtual-obmc-host-ipmi-hw"
