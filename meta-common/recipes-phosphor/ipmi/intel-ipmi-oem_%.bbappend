FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/intel-ipmi-oem.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "2c3a94cdc2b335a0c56c2fdb107270bc35505336"

EXTRA_OECMAKE +=" if-non-intel-disable=OFF"
