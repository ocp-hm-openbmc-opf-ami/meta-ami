FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI:append = " file://0001-ARP-Control.patch \
                    file://0002-VLAN-Priority.patch"


SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.GARPControl.service"

