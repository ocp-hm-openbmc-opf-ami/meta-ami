FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:s997 = " file://virtual_sensor_config.json"

do_install:append:s997() {
    install -d ${D}${datadir}/phosphor-virtual-sensor
    install -m 0644 ${UNPACKDIR}/virtual_sensor_config.json \
        ${D}${datadir}/phosphor-virtual-sensor/virtual_sensor_config.json
}
