SUMMARY = "Sensor History Reader"
DESCRIPTION = "collecting of all the sensor values every given interval"

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=65a69a674f34a9f30737c9f0abd4fc5c"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/sensor-history-reader.git;protocol=https;branch=master"
SRCREV = "0d921746622f9cebf18c87fa17a02511dd039a1b"

PV = "0.0+git${SRCPV}"

S = "${UNPACKDIR}/git"

inherit meson pkgconfig
inherit python3native
inherit systemd

EXTRA_OEMESON += "-Dcpp_std=c++23"

FILES:${PN} += "${systemd_system_unitdir}/xyz.openbmc_project.SensorReader.service"
SYSTEMD_SERVICE:${PN} = "xyz.openbmc_project.SensorReader.service"

DEPENDS += " \
    systemd \
    autoconf-archive-native \
    sdbusplus \
    sdbusplus ${PYTHON_PN}-sdbus++-native \
    phosphor-logging \
    stdplus \
    boost \
    nlohmann-json \
    "

do_install:append() {

         install -d ${D}/etc/sensor-reader-conf
         install -m 0644 ${S}/configuredsensors ${D}/etc/sensor-reader-conf/
}
