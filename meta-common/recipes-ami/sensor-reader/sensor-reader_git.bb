SUMMARY = "Sensor History Reader"
DESCRIPTION = "collecting of all the sensor values every given interval"

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=65a69a674f34a9f30737c9f0abd4fc5c"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/sensor-history-reader.git;protocol=https;branch=integrate-onetree-3.1.1"
SRCREV = "e56311bf7d48c85e78f87d4868672d12b3aff81c"

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
