SUMMARY = "Sensor History Reader"
DESCRIPTION = "collecting of all the sensor values every given interval"

LICENSE = "CLOSED"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/sensor-history-reader.git;protocol=https;branch=master"
SRCREV = "9074512f5e79637415507f26327c3e2b47d30aab"

PV = "0.0+git${SRCPV}"

S = "${WORKDIR}/git"

inherit cmake
inherit meson pkgconfig
inherit python3native
inherit systemd

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

        install -d ${D}/etc/sensor-reader
        install -m 0644 ${S}/configuredsensors ${D}/etc/sensor-reader/
        install -m 0644 ${S}/configuredsensors ${D}/etc/sensor-reader/
}
