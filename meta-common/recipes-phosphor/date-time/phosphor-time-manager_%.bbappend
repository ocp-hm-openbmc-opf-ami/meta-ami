FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-time-manager.git;branch=integrate-onetree-3.1.1;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "303bb8cc402c13d4a6eb364959310ddb94bfd192"

DBUS_SERVICE:${PN} += "xyz.openbmc_project.NTPSec.Manager.service"
