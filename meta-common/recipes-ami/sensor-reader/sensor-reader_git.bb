SUMMARY = "Sensor History Reader"
DESCRIPTION = "collecting of all the sensor values every given interval"

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=65a69a674f34a9f30737c9f0abd4fc5c"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/sensor-history-reader.git;protocol=https;branch=integrate-onetree-latest"
SRCREV = "6ef417e95fa3cb30cd79c80554b21a95f4618db8"

PV = "0.0+git${SRCPV}"

S = "${UNPACKDIR}/git"

inherit meson pkgconfig
inherit python3native
inherit systemd

EXTRA_OEMESON += "-Dcpp_std=c++23"

# Unit tests + code coverage (opt-in). Set SENSOR_READER_UT = "1" to enable:
#   - meson '-Dtests=enabled' gates subdir('tests') (see meson.options).
#   - '-Db_coverage=true' turns on gcov instrumentation.
#   - 'gtest' is added to DEPENDS so gtest/gmock are in the sysroot.
SENSOR_READER_UT ?= "0"
EXTRA_OEMESON:append = "${@bb.utils.contains('SENSOR_READER_UT', '1', ' -Dtests=enabled -Db_coverage=true', ' -Dtests=disabled -Db_coverage=false', d)}"

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

# GTest/GMock for unit tests (provides both gtest and gmock); pulled in only
# when SENSOR_READER_UT is enabled.
DEPENDS:append = "${@bb.utils.contains('SENSOR_READER_UT', '1', ' gtest', '', d)}"

do_install:append() {

         install -d ${D}/etc/sensor-reader-conf
         install -m 0644 ${S}/configuredsensors ${D}/etc/sensor-reader-conf/
}
