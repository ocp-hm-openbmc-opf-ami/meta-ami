FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

RDEPENDS:${PN} += " libapisensor"
SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/dbus-sensors;protocol=https;branch=main;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "541b758c11bdaa766c0fd5dd118006aa37df6773"

SRC_URI:append = "\
     file://intrusionsensor-depend-on-networkd.conf \
     "
SRC_URI_EGS:append =  " \
             file://0001-converted-index-to-0-based-and-made-pwm-starts-from-.patch \
             "
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'egs', SRC_URI_EGS, '', d)}"

PACKAGECONFIG[processorstatus] = "-Dprocstatus=enabled, -Dprocstatus=disabled"
PACKAGECONFIG[systemsensor] = "-Dsystem=enabled, -Dsystem=disabled"
PACKAGECONFIG[powerunitstatus] = "-Dpowerunit=enabled, -Dpowerunit=disabled"
PACKAGECONFIG[acpisystemstatus] = "-Dacpisystem=enabled, -Dacpisystem=disabled"
PACKAGECONFIG[psustatus] = "-Dpsustatus=enabled, -Dpsustatus=disabled"
PACKAGECONFIG[osstatus] = "-Dosstatus=enabled, -Dosstatus=disabled"
PACKAGECONFIG[batterystatus] = "-Dbatterystatus=enabled, -Dbatterystatus=disabled"
PACKAGECONFIG[acpidevicestatus] = "-Dacpidevice=enabled, -Dacpidevice=disabled"
PACKAGECONFIG[digital] = "-Ddigital=enabled, -Ddigital=disabled"
PACKAGECONFIG[bmcfirmwarehealth] = "-Dbmc-firmware-health=enabled, -Dbmc-firmware-health=disabled"
PACKAGECONFIG[damagedsensor] = "-Ddamaged-sensor=enabled, -Ddamaged-sensor=disabled"
PACKAGECONFIG[logstatus] = "-Dlogstatus=enabled, -Dlogstatus=disabled"
PACKAGECONFIG[apisensor] = "-Dapisensor=enabled, -Dapisensor=disabled"
PACKAGECONFIG[dbusadcsensor] = "-Ddbus-adc=enabled, -Ddbus-adc=disabled"
PACKAGECONFIG[external] = "-Dexternal=enabled, -Dexternal=disabled"

PACKAGECONFIG:append = " processorstatus \
            systemsensor \
            powerunitstatus \
            acpisystemstatus \
            psustatus \
            osstatus \
            batterystatus \
            acpidevicestatus \
            digital \
            bmcfirmwarehealth \
            damagedsensor \
            logstatus \
            apisensor \
            external \
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

SYSTEMD_SERVICE:${PN}:append = " ${@bb.utils.contains('PACKAGECONFIG', 'psustatus', \
                                               'xyz.openbmc_project.psustatus.service', \
                                               '', d)}"

SYSTEMD_SERVICE:${PN}:append = " ${@bb.utils.contains('PACKAGECONFIG', 'osstatus', \
                                               'xyz.openbmc_project.osstatus.service', \
                                               '', d)}"

SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'batterystatus', \
                                               'xyz.openbmc_project.batterystatus.service', \
                                               '', d)}"

SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'acpidevicestatus', \
                                               'xyz.openbmc_project.acpidevicestatus.service', \
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
SYSTEMD_SERVICE:${PN}:append = " ${@bb.utils.contains('PACKAGECONFIG', 'logstatus', \
                                               'xyz.openbmc_project.logstatus.service', \
                                               '', d)}"

# APISENSOR REACTOR
NUM_APISENSOR_REACTORS ?= "5"
EXTRA_OEMESON += "${@bb.utils.contains('PACKAGECONFIG', 'apisensor', '-Dnum_apisensor_reactors=${NUM_APISENSOR_REACTORS}', '', d)}"

SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'apisensor', \
    ' '.join(['xyz.openbmc_project.apisensor@%d.service' % i \
    for i in range(1, int(d.getVar('NUM_APISENSOR_REACTORS')) + 1)]), '', d)}"



FILES:${PN} += "${systemd_system_unitdir}/xyz.openbmc_project.apisensor@*.service"

