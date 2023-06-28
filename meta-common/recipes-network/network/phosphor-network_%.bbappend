FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "a4c18d4e50b74f1c19ebdfaaf7073ab89d6524bb"

SRC_URI:append = " \
	     file://0001-ARP-Control.patch \
             file://0006-keep-IPv6AcceptRA-TRUE-when-enable-ipv6-static.patch \
             file://0007-IP-Gateway-Validation-When-Set-To-Static.patch \
             file://0008-Reload-Network-After-Reset-Conf.patch \
             file://0009-removed-error-message-ingnoring-function-when-settin.patch \
	     file://0010-Allow-empty-gateway6-when-ipv6-source-is-static.patch \
             file://0010-Fix-Cannot-Communicate-With-Vlan-IP-By-IPMI-Command.patch \
             file://0011-Fix-Dynamic-And-Static-Addrs-Shown-When-IPSrc-Is-DHCP.patch \
             file://0013-Add-Prefix-Length-at-Neighbor.patch \
             file://0013-Allow-Empty-Gateway4-When-IPv4-Source-Is-Static.patch \
             file://nsupdate.sh \
             file://0015-Implement-EIP-741000.-DDNS-Nsupdate-Feature.patch \
             file://0014-Fix-No-Default-GW-MAC-Address.patch \
             file://0016-Add-Function-IPv4-IPv6-Enabled-Disabled.patch \
           "

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/nsupdate.sh  ${D}${bindir}
}


EXTRA_OEMESON:append = " -Dpersist-mac=true"

EXTRA_OEMESON:append = " -Ddefault-link-local-autoconf=ipv6"

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.GARPControl.service"
