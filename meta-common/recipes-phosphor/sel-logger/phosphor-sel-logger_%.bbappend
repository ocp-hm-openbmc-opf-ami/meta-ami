FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PROJECT_SRC_DIR := "${THISDIR}/${PN}"

SRCREV="c68ea0522ac6630dbe50829845a11f335cf87800"
SRC_URI += "\
        file://0001-Add-PEF-support-for-SEL-Events.patch \
        file://0002-Add-Linear-SEL-Support.patch \
        file://0003-Add-Support-to-handle-OS-Critical-Sensor-Event.patch \
        file://0004-Add-DBus-SEL-Logging-support.patch \
        file://0005-Add-Systemd-Unit-crash-logging-support.patch \
"
SRC_URI_AST2600:append = " \
			file://0006-i2cbusfault-logging-AST2600.patch \
			"
SRC_URI_AST2700:append = " \
                        file://0007-i2cbusfault-logging-AST2700.patch \
                        "

DEPENDS += "intel-ipmi-oem"
RDEPENDS:${PN} += "intel-ipmi-oem"

PACKAGECONFIG:append = " send-to-logger log-threshold log-crash"

SRC_URI:append = "${@bb.utils.contains('MACHINE', 'evb-ast2600', SRC_URI_AST2600, '', d)}"
SRC_URI:append = "${@bb.utils.contains('MACHINE', 'ast2700-default', SRC_URI_AST2700, '', d)}"

PACKAGECONFIG[i2c-bus-fault] = "-Di2c-bus-fault=true,-Di2c-bus-fault=false"
PACKAGECONFIG:append = " i2c-bus-fault"
