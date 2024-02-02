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

DEPENDS += "intel-ipmi-oem"
RDEPENDS:${PN} += "intel-ipmi-oem"

PACKAGECONFIG:append = " send-to-logger log-threshold log-crash"
