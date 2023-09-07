FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "88a32137fb8173970e2bda25c41561b837f89f7d"

SRC_URI:append = " \
            file://0001-converted-index-to-0-based-and-made-pwm-starts-from-.patch \
            file://0006-disable-unsupported-sensors.patch\
            file://0008-Fix-For-CPU-Sensor-dbus-entry-is-not-creating.patch \
            file://0009-Fix-for-Fan-Redundancy.patch \
            file://0010-Add-Processor-presence-support.patch \
            file://0011-Add-watchdog2-support.patch \
            file://0012-Adding-Sensor-threshold-support-for-nm-sensor.patch \
            file://0013-Adding-ast2600-compatible-string-for-FanTypes-of-asp.patch \
            "

PACKAGECONFIG[processorstatus] = "-Dprocstatus=enabled, -Dprocstatus=disabled"
PACKAGECONFIG[systemsensor] = "-Dsystem=enabled, -Dsystem=enabled"

PACKAGECONFIG:append = "processorstatus \
            systemsensor \
"

SYSTEMD_SERVICE:${PN}:append = " ${@bb.utils.contains('PACKAGECONFIG', 'processorstatus', \
                                               'xyz.openbmc_project.processorstatus.service', \
                                               '', d)}"

SYSTEMD_SERVICE:${PN}:append = " ${@bb.utils.contains('PACKAGECONFIG', 'systemsensor', \
                                               'xyz.openbmc_project.systemsensor.service', \
                                               '', d)}"
