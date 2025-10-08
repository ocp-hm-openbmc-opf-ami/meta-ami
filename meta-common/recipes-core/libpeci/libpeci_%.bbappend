# Enable downstream autobump
# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/libpeci;branch=master;protocol=https"
SRCREV = "f6e3f1629dd3d98d205707faa2a1c8267a0a38a7"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
        file://99-peci.rules \
	file://0001-Enable-64-bit-RdPkgConfig-and-WrPkgConfig-transfers.patch \
        file://0002-Add-PECI-Telemetry-command.patch \
        file://0003-Add-single-dev-peci-i3c-node-abstraction.patch \
        file://0005-Added_peci_wakeup_support_for_lib_peci.patch \
        file://0006-fix-for-cups-context-switch.patch \
"

do_install:append() {
    install -d ${D}${libdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/99-peci.rules ${D}${libdir}/udev/rules.d
}

PACKAGECONFIG:append:intel = " dbus-raw-peci"
