FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "61baea42b86c74f5c6350f669f889d9d2a728be4"

SRC_URI += "file://0001-converted-index-to-0-based-and-made-pwm-starts-from-.patch \
	    file://0002-Add-Processor-Type-Sensor-Support.patch \
            file://0003-ProcessorSensor-Replace-iterator-pairs-with-structur.patch \
	    file://0004-Add-Watchdog2-Discrete-Sensor.patch \
	    file://0005-Add-Severity-Information-For-Discrete-Sensor.patch \
            "

PACKAGECONFIG[processorstatus] = "-Dprocstatus=enabled, -Dprocstatus=disabled"
PACKAGECONFIG[systemsensor] = "-Dsystem=enabled, -Dsystem=enabled"

PACKAGECONFIG:append += "processorstatus \
			 systemsensor \
"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'processorstatus', \
                                               'xyz.openbmc_project.processorstatus.service', \
                                               '', d)}"

SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'systemsensor', \
                                               'xyz.openbmc_project.systemsensor.service', \
                                               '', d)}"

