FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-converted-index-to-0-based-and-made-pwm-starts-from-.patch \
	    file://0002-Add-Processor-Type-Sensor-Support.patch \
            "

PACKAGECONFIG[processorstatus] = "-Dprocstatus=enabled, -Dprocstatus=disabled"

PACKAGECONFIG:append += "processorstatus \
"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'processorstatus', \
                                               'xyz.openbmc_project.processorstatus.service', \
                                               '', d)}"


