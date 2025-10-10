FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-networkd;protocol=https;branch=main;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "94a8e947e2f41879e8820fd73b72017a7a63b768"

SRC_URI:append = " \
             file://ipv4-advanced-route.sh \
             file://ipv6-advanced-route.sh \
             file://nsupdate.sh \
             "


do_install:append() {
    install -d ${D}${bindir}
    if [ "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-nsupdate-support', 'true', '', d)}" == "true" ];  then
        install -m 0755 ${WORKDIR}/nsupdate.sh ${D}${bindir}
    fi

    if [ "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-advanced-route-support', 'true', '', d)}" == "true" ]; then
        install -m 0755 ${WORKDIR}/ipv6-advanced-route.sh ${D}${bindir}
        install -m 0755 ${WORKDIR}/ipv4-advanced-route.sh ${D}${bindir}
    fi

    install -d -m 0755 ${D}/etc/sysctl.d
    echo "net.ipv4.tcp_timestamps=0" >> ${D}/etc/sysctl.d/99-network.conf

    if [ "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-disable-ping-support', 'true', '', d)}" == "true" ]; then
        echo "net.ipv4.icmp_echo_ignore_all=1" >> ${D}/etc/sysctl.d/99-network.conf
        echo "net.ipv6.icmp.echo_ignore_all=1" >> ${D}/etc/sysctl.d/99-network.conf
        echo "net.ipv4.conf.all.arp_ignore=1" >> ${D}/etc/sysctl.d/99-network.conf
        echo "net.ipv4.conf.default.arp_ignore=1" >> ${D}/etc/sysctl.d/99-network.conf
    fi
}

EXTRA_OEMESON:append = " -Dpersist-mac=false"

EXTRA_OEMESON:append = " -Ddefault-link-local-autoconf=ipv6"

EXTRA_OEMESON:append = " -Denable-advanced-route=false"

EXTRA_OEMESON:append = " -Denable-system-firewall=false"

EXTRA_OEMESON:append = " -Denable-bond-feature=false"

EXTRA_OEMESON:append = " -Denable-phy-configuration=false"

EXTRA_OEMESON:append = " -Dncsi-keep-phy-link-up=false"

EXTRA_OEMESON:append = " -Dncsi-flow-control=false"

EXTRA_OEMESON:append = " -Denable-nsupdate-feature=false"

EXTRA_OEMESON:append = " -Denable-tsig-feature=false"

EXTRA_OEMESON:append = " -Denable-avahi-support=false"

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.GARPControl.service"


EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-advanced-route-support', ' -Denable-advanced-route=true','', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-system-firewall-support', ' -Denable-system-firewall=true','', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('ENABLE_BONDING', 'network-bond', ' -Denable-bond-feature=true','', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-avahi-support', ' -Denable-avahi-support=true','', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-nsupdate-support', ' -Denable-nsupdate-feature=true','', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-nsupdate-support', bb.utils.contains('IMAGE_FEATURES', 'onetree-network-tsig-support', ' -Denable-tsig-feature=true', '', d), '', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-persist-mac-support', ' -Dpersist-mac=true','', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-phy-configuration-support', ' -Denable-phy-configuration=true','', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-ncsi-support', ' -Denable-ncsi=true -Ddefault-ncsi-interface=eth2','', d)}"
