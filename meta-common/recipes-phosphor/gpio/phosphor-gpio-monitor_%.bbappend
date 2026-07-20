FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-gpio-monitor.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "496d5c3687f3bdcc8c7c89d99fe405a8c443fe2e"
