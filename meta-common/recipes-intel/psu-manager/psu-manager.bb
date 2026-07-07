SUMMARY = "Power supply manager for Intel based platform"
DESCRIPTION = "Power supply manager which include PSU Cold Redundancy service"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/psu-manager.git;protocol=https;branch=main"
SRCREV = "4c8f6f628b76b24abf3ccb31a89fefff16eb1643"

S = "${UNPACKDIR}/git"

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
