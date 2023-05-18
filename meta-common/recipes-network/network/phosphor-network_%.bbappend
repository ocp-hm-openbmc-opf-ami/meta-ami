FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "a4c18d4e50b74f1c19ebdfaaf7073ab89d6524bb"

SRC_URI:append = " \
	     file://0001-ARP-Control.patch \
             file://0006-keep-IPv6AcceptRA-TRUE-when-enable-ipv6-static.patch \
             file://0007-IP-Gateway-Validation-When-Set-To-Static.patch \
             file://0008-Reload-Network-After-Reset-Conf.patch \
           "


EXTRA_OEMESON:append = " -Dpersist-mac=true"

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.GARPControl.service"
