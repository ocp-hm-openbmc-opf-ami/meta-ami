FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-time-manager.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "f3d4862fbd2c9879ccb981746aba14eeae487f22"

DBUS_SERVICE:${PN} += "xyz.openbmc_project.NTPSec.Manager.service"
