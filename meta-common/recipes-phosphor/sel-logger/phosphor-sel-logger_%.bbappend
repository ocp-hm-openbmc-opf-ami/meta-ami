FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PROJECT_SRC_DIR := "${THISDIR}/${PN}"

#SRCREV="9fa224c5eadf64505ef2c41334f7125fe899176b"

SRCREV="483ae8f09371cadeda4be02d8c109ac5dae5a98e"


SRC_URI += " \
           file://0001-Add-PEF-support-for-SEL-Events.patch \
           file://0002-Add-Linear-SEL-Support.patch \
           file://0003-Add-Support-to-handle-OS-Critical-Sensor-Event.patch \
           file://0004-Add-D-Bus-SEL-Logging-and-SEL-Policy-support.patch \
           file://0005-Add-Systemd-Unit-crash-logging-support.patch \
           file://0006-Add-Logging-event-basaed-on-severity.patch \
           "


DEPENDS += "intel-ipmi-oem"
RDEPENDS:${PN} += "intel-ipmi-oem"

PACKAGECONFIG:append = " send-to-logger log-threshold log-crash"
