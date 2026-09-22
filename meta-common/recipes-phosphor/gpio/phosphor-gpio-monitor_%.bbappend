FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-gpio-monitor.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "fa05e77db57070f4932db03c08608cfdaf950473"
