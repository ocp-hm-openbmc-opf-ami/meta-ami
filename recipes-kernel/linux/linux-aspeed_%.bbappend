FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://usb-eth.cfg \
    file://0011-Enable-Threshold-Attributes-for-Core-temperature-sen.patch \
    file://0001-In-hwmon-driver-fan-and-pwm-starts-from-1-as-per-spe.patch \
    file://0001-Fix-virtual-USB-hub-not-working-for-evb-ast2600.patch \
    "
