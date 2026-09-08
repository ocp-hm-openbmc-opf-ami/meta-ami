FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-gpio-monitor.git;branch=integrate-onetree-3.1.1;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "6f9dfff0d8c412bc3b4d0c9795c4ad4a9d3fc4aa"
