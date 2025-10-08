SUMMARY = "Power supply manager for Intel based platform"
DESCRIPTION = "Power supply manager which include PSU Cold Redundancy service"

SRC_URI = "git://git@github.com/intel-bmc/firmware.bmc.openbmc.applications.psu-manager.git;protocol=ssh;branch=main"
SRCREV = "b049f4086a1c95e340d773b7905c39d491a90e7f"

S = "${WORKDIR}/git"

PV = "1.0+git${SRCPV}"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${S}/LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

inherit cmake
inherit pkgconfig
inherit systemd

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.coldredundancy.service"

DEPENDS += " \
    systemd \
    sdbusplus \
    phosphor-dbus-interfaces \
    phosphor-logging \
    boost \
    i2c-tools \
    "
