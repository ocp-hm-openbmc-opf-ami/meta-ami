FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PROJECT_SRC_DIR := "${THISDIR}/${PN}"

# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/dbus-sensors.git;branch=master;protocol=https"
SRCREV = "ae4639667132e9bca62277815f0dca5c77c0b887"

# The below patch changes are moved into internal dbus-sensors repo
# so, not required to apply the below patches
# intrusionsensor-depend-on-networkd.conf file moved to meta-ami ,not required to apply with meta-ami

INTEL_SRC_URI += "\
    file://10-nice-rules.conf \
    file://intrusionsensor-depend-on-networkd.conf \
    file://0001-PSUSensor-support-PWM-mode-control-of-PSU-fan.patch \
    file://0001-Add-check-for-min-max-received-from-hwmon-files.patch \
    file://0002-Fix-PECI-client-creation-flow.patch \
    file://0003-Fix-missing-threshold-de-assert-event-when-threshold.patch \
    file://0004-Fan-Tach-Sensor-Threshold-Ignore-Zero.patch \
    file://0005-Fix-PECI-ioctl-number.patch \
    file://0006-CPUSensor-create-RequiredTempSensor-if-defined.patch \
    file://0007-Add-support-for-the-energy-hwmon-type.patch \
    file://0008-CPUSensor-update-threshold-when-Tcontrol-changes.patch \
    file://0009-CPUSensor-Create-CPUConfig-for-each-PECI-adapter.patch \
    file://0010-Add-support-for-Get-PMBUS-Readings-method.patch \
    file://0012-Ignore-VR-sensor-readings-if-content-is-0xFF.patch \
    file://0013-psusensor-Determine-PSU-threshold-dynamically.patch \
    file://0013-psusensor-only-call-checkEventLimits-for-psu.patch \
    file://0014-intelcpusensor-use-yield-context-in-sensor-polling.patch \
    file://0015-IntelCPUSensor-use-bus-name-to-communicate-with-PECI.patch \
    file://0016-intelcpusensor-Update-CPUConfig-set-based-on-udev-ev.patch \
    file://0017-DBus-ADC-sensors-exposure.patch \
    file://0018-Add-I2C-ADC-Sensor-Support.patch \
    file://0019-psusensor-add-filter-for-VR-temperature-sensor.patch \
    file://0017-hwmontempsensor-Handle-failure-to-canonicalize-devic.patch \
    file://0018-psusensor-increment-error-count-if-read-fail.patch \
    file://0019-psusensor-Fix-memory-leak.patch \
    "
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'meta-ami', '',INTEL_SRC_URI, d)}"
DEPENDS:append = " libgpiod libmctp systemd"

PACKAGECONFIG[dbusadcsensor] = "-Ddbus-adc=enabled, -Ddbus-adc=disabled"
SYSTEMD_SERVICE:${PN}:append = "${@bb.utils.contains('PACKAGECONFIG', 'dbusadcsensor', \
                                               ' xyz.openbmc_project.dbusadcsensor.service', \
                                               '', d)}"

PACKAGECONFIG += " \
    adcsensor \
    exitairtempsensor \
    fansensor \
    hwmontempsensor \
    intelcpusensor \
    intrusionsensor \
    ipmbsensor \
    mcutempsensor \
    psusensor \
"

# Enable Validation unsecure based on IMAGE_FEATURES
EXTRA_OEMESON += "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'validation-unsecure', '-Dvalidate-unsecure-feature=enabled', '', d)}"

do_install:append() {
    svc="xyz.openbmc_project.intrusionsensor.service"
    srcf="${WORKDIR}/intrusionsensor-depend-on-networkd.conf"
    dstf="${D}/etc/systemd/system/${svc}.d/10-depend-on-networkd.conf"
    mkdir -p "${D}/etc/systemd/system/${svc}.d"
    install "${srcf}" "${dstf}"

#svc="xyz.openbmc_project.intelcpusensor.service"
#srcf="${WORKDIR}/10-nice-rules.conf"
#dstf="${D}/etc/systemd/system/${svc}.d/10-nice-rules.conf"
#mkdir -p "${D}/etc/systemd/system/${svc}.d"
#install "${srcf}" "${dstf}"
#
#svc="xyz.openbmc_project.psusensor.service"
#dstf="${D}/etc/systemd/system/${svc}.d/10-nice-rules.conf"
#mkdir -p "${D}/etc/systemd/system/${svc}.d"
#install "${srcf}" "${dstf}"
}
