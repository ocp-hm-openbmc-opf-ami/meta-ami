FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PROJECT_SRC_DIR := "${THISDIR}/${PN}"


SRC_URI += "\
        file://0001-Add-PEF-support-for-SEL-Events.patch \
        file://0002-Add-Linear-SEL-Support.patch \
        file://0003-Add-Support-to-handle-OS-Critical-Sensor-Event.patch \
"

DEPENDS += "intel-ipmi-oem"
RDEPENDS:${PN} += "intel-ipmi-oem"


PACKAGECONFIG:append:intel = " clears-sel"
