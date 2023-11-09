FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

NETWORK_BONDING_SRC_URI += "file://0023-Support-Network-Bonding.patch \
                            file://0027-Bond_Function_With_Static_IP_Address_Is_Not_Working_Properly.patch \
                           "


SRC_URI:append = " \
             file://0001-ARP-Control.patch \
             file://0006-keep-IPv6AcceptRA-TRUE-when-enable-ipv6-static.patch \
             file://0007-IP-Gateway-Validation-When-Set-To-Static.patch \
             file://0009-removed-error-message-ingnoring-function-when-settin.patch \
             file://0010-Allow-empty-gateway6-when-ipv6-source-is-static.patch \
             file://0010-Fix-Cannot-Communicate-With-Vlan-IP-By-IPMI-Command.patch \
             file://0011-Fix-Dynamic-And-Static-Addrs-Shown-When-IPSrc-Is-DHCP.patch \
             file://0013-Add-Prefix-Length-at-Neighbor.patch \
             file://0013-Allow-Empty-Gateway4-When-IPv4-Source-Is-Static.patch \
             file://nsupdate.sh \
             file://0015-Implement-DDNS-Nsupdate-With-TSIG.patch \
             file://0014-Fix-No-Default-GW-MAC-Address.patch \
             file://0016-Add-Function-IPv4-IPv6-Enabled-Disabled.patch \
             file://0017-Fix-property-of-DomainName-in-each-EthernetInterface-Returns-Empty.patch \
             file://0018-Add-VLAN_MAX_NUM-for-not-creating-VLAN-interfaces-over-size.patch \
             file://0019-Fix-Defaultgateway6-Is-Zero-When-Setting-More-Than-One_IPv6.patch \
             file://0020-Fix-Remove-Empty-Gateway-and-Static-Gateway-Missing-and-Add-Gateway-Check-Condition.patch \
             file://0021-Add-Function-to-Save-IPv6-Static-Router-Control.patch \
             file://0022-Enable-Advanced-Route.patch \
             file://ipv4-advanced-route.sh \
             file://ipv6-advanced-route.sh \
             file://0022-Re-Design-the-RA-part-in-DHCPEnabled.patch \
             file://0024-Check-if-IPv4-and-Default-Gateway-are-in-the-Same-Series.patch \
             ${@bb.utils.contains('ENABLE_BONDING', 'network-bond', NETWORK_BONDING_SRC_URI,'', d)} \
             file://0026-Catch-More-Exceptions-to-Avoid-Invalid-MACAddress-while-Decoding.patch \
             file://0024-Add-Index-of-IPAddress-and-its-Related-Function.patch \
          "


do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/nsupdate.sh  ${D}${bindir}

    install -m 0755 ${WORKDIR}/ipv6-advanced-route.sh ${D}${bindir}
    install -m 0755 ${WORKDIR}/ipv4-advanced-route.sh ${D}${bindir}

}

EXTRA_OEMESON:append = " -Dpersist-mac=true"

EXTRA_OEMESON:append = " -Ddefault-link-local-autoconf=ipv6"

EXTRA_OEMESON:append = " -Denable-advanced-route=true"

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.GARPControl.service"


