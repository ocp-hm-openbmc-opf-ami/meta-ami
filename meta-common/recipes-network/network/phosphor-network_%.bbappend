FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-networkd;protocol=https;branch=integrate-onetree-3.1.1;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "c0ec846a3ccb8e7fcebb772aec9807997b23483d"

SRC_URI:append = " \
             file://ipv4-advanced-route.sh \
             file://ipv6-advanced-route.sh \
             file://nsupdate.sh \
             file://https-dns-proxy.sh \
             "


do_install:append() {
    install -d ${D}${bindir}

    if ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-nsupdate-support', 'true', 'false', d)}; then
        install -m 0755 ${UNPACKDIR}/https-dns-proxy.sh ${D}${bindir}
        install -m 0755 ${UNPACKDIR}/nsupdate.sh ${D}${bindir}
    fi

    if ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-advanced-route-support', 'true', 'false', d)}; then
        install -m 0755 ${UNPACKDIR}/ipv6-advanced-route.sh ${D}${bindir}
        install -m 0755 ${UNPACKDIR}/ipv4-advanced-route.sh ${D}${bindir}
    fi

    install -d -m 0755 ${D}/etc/sysctl.d
    echo "net.ipv4.tcp_timestamps=0" >> ${D}/etc/sysctl.d/99-network.conf

    if ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-disable-ping-support', 'true', 'false', d)}; then
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

EXTRA_OEMESON:append = " -Denable-doh-support=false"

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.GARPControl.service"


EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-advanced-route-support', ' -Denable-advanced-route=true','', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-system-firewall-support', ' -Denable-system-firewall=true','', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-disable-ping-support', ' -Ddisable-ping-support=true',' -Ddisable-ping-support=false', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('ENABLE_BONDING', 'network-bond', ' -Denable-bond-feature=true','', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-doh-support', ' -Denable-doh-support=true','', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-avahi-support', ' -Denable-avahi-support=true','', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-nsupdate-support', ' -Denable-nsupdate-feature=true','', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-nsupdate-support', bb.utils.contains('IMAGE_FEATURES', 'onetree-network-tsig-support', ' -Denable-tsig-feature=true', '', d), '', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-persist-mac-support', ' -Dpersist-mac=true','', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-phy-configuration-support', ' -Denable-phy-configuration=true','', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-ncsi-support', ' -Denable-ncsi=true -Ddefault-ncsi-interface=eth2','', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-ncsi-manual-detect-support', ' -Dncsi-manual-detect=true',' -Dncsi-manual-detect=false ', d)}"
