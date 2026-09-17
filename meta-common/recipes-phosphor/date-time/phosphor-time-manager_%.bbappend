FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-time-manager.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "945ec5e1a0814379ac1bb8e9153471a3627c7e77"

DBUS_SERVICE:${PN} += "xyz.openbmc_project.NTPSec.Manager.service"
