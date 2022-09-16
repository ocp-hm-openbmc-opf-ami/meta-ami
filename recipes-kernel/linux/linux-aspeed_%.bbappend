FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://usb-eth.cfg \
    file://0001-aspeed-bmc-intel-ast2600-acm-dts.patch \
    file://0011-Enable-Threshold-Attributes-for-Core-temperature-sen.patch \
    "
