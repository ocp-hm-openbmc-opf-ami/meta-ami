FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "f7dce2e866821caa28010ee5d869e01f0de905a4"

SRC_URI += " file://0001-ARP-Control.patch \
             file://0002-VLAN-Priority.patch \
           "


SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.GARPControl.service"
