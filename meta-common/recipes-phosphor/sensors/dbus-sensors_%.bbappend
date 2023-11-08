FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
            file://0001-converted-index-to-0-based-and-made-pwm-starts-from-.patch\
            file://0006-disable-unsupported-sensors.patch\
            file://0008-Fix-For-CPU-Sensor-dbus-entry-is-not-creating.patch \
            file://0009-Fix-for-Fan-Redundancy.patch \
            file://0010-Add-Processor-presence-support.patch \
            file://0011-Add-watchdog2-support.patch \
            file://0013-Adding-ast2600-compatible-string-for-FanTypes-of-asp.patch \
            file://0014-Add-power-unit-dicrete-sensor.patch \
            file://0015-ACPI-System-discrete-sensor.patch \
            file://0016-Add-Power-Supply-Sensor-Support.patch \
            file://0017-Update-Discrete-Processor-and-Watchdog2-sensors.patch \
            file://0018-Add-OS-Critical-Stop-DS-Support.patch \
            file://0019-Fix-for-Nm-Sensor-Threshold.patch \
            "

PACKAGECONFIG[processorstatus] = "-Dprocstatus=enabled, -Dprocstatus=disabled"
PACKAGECONFIG[systemsensor] = "-Dsystem=enabled, -Dsystem=enabled"
PACKAGECONFIG[powerunitstatus] = "-Dpowerunit=enabled, -Dpowerunit=disabled"
PACKAGECONFIG[acpisystemstatus] = "-Dacpisystem=enabled, -Dacpisystem=disabled"
PACKAGECONFIG[psustatus] = "-Dpsustatus=enabled, -Dpsustatus=disabled"
PACKAGECONFIG[osstatus] = "-Dosstatus=enabled, -Dosstatus=disabled"

PACKAGECONFIG:append = " processorstatus \
            systemsensor \
            powerunitstatus \
            acpisystemstatus \
            psustatus \
            osstatus \
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

