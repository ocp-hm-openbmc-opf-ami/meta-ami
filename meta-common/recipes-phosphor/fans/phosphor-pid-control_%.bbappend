FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-pid-control.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "bb76aa69e72b9b92d0ea7ba9d0c2be8d3a672e0c"

