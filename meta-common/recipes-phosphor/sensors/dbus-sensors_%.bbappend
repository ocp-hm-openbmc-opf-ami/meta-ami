FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/dbus-sensors.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "51c9007fdbfb9f4a8a2fffb9fd5956560e447aa9"

SRC_URI_ast2600:append =  " \
            file://0001-ADCSensor-Fix-for-P3V3-sensor.patch \
            "
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'ast2600', SRC_URI_ast2600, '', d)}"

SRC_URI:append = "\
    file://intrusionsensor-depend-on-networkd.conf \
    "
SRC_URI_EGS:append =  " \
            file://0001-converted-index-to-0-based-and-made-pwm-starts-from-.patch \
            "
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'egs', SRC_URI_EGS, '', d)}"

PACKAGECONFIG[processorstatus] = "-Dprocstatus=enabled, -Dprocstatus=disabled"
PACKAGECONFIG[systemsensor] = "-Dsystem=enabled, -Dsystem=enabled"
PACKAGECONFIG[powerunitstatus] = "-Dpowerunit=enabled, -Dpowerunit=disabled"
PACKAGECONFIG[acpisystemstatus] = "-Dacpisystem=enabled, -Dacpisystem=disabled"
PACKAGECONFIG[psustatus] = "-Dpsustatus=enabled, -Dpsustatus=disabled"
PACKAGECONFIG[osstatus] = "-Dosstatus=enabled, -Dosstatus=disabled"
PACKAGECONFIG[batterystatus] = "-Dbatterystatus=enabled, -Dbatterystatus=disabled"
PACKAGECONFIG[acpidevicestatus] = "-Dacpidevice=enabled, -Dacpidevice=disabled"
PACKAGECONFIG[digital] = "-Ddigital=enabled, -Ddigital=disabled"

PACKAGECONFIG:append = " processorstatus \
            systemsensor \
            powerunitstatus \
            acpisystemstatus \
            psustatus \
            osstatus \
            batterystatus \
            acpidevicestatus \
            digital \
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



