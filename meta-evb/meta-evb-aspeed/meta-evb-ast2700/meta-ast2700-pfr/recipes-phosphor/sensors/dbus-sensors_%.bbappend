FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

PACKAGECONFIG:append = " processorstatus \
            systemsensor \
            powerunitstatus \
            acpisystemstatus \
            osstatus \
            digital \
            bmcfirmwarehealth \
            damagedsensor \
            psusensor \
"

SYSTEMD_SERVICE:${PN}:append = " ${@bb.utils.contains('PACKAGECONFIG', 'processorstatus', \
                                               'xyz.openbmc_project.processorstatus.service', \
                                               '', d)}"

SYSTEMD_SERVICE:${PN}:append = " ${@bb.utils.contains('PACKAGECONFIG', 'systemsensor', \
                                               'xyz.openbmc_project.systemsensor.service', \
                                               '', d)}"

SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'powerunitstatus', \
                                               'xyz.openbmc_project.powerunitstatus.service', \
                                               '', d)}"

SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'acpisystemstatus', \
                                               'xyz.openbmc_project.acpisystemstatus.service', \
                                               '', d)}"

SYSTEMD_SERVICE:${PN}:append = " ${@bb.utils.contains('PACKAGECONFIG', 'osstatus', \
                                               'xyz.openbmc_project.osstatus.service', \
                                               '', d)}"

SYSTEMD_SERVICE:${PN}:append = " ${@bb.utils.contains('PACKAGECONFIG', 'digital', \
                                               'xyz.openbmc_project.digitaldiscrete.service', \
                                               '', d)}"

SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'bmcfirmwarehealth', \
                                               'xyz.openbmc_project.bmcfirmwarehealth.service', \
                                               '', d)}"

SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'damagedsensor', \
                                               'xyz.openbmc_project.damagedsensor.service', \
                                               '', d)}"
