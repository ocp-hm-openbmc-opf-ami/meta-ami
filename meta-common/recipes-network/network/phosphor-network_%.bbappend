FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-networkd;branch=main;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "0c19dcd917a3464f9a9f8de52b13c8e0280f1652"

SRC_URI:append = " \
             file://ipv4-advanced-route.sh \
             file://ipv6-advanced-route.sh \
             file://nsupdate.sh \
             "


do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/nsupdate.sh  ${D}${bindir}

    install -m 0755 ${WORKDIR}/ipv6-advanced-route.sh ${D}${bindir}
    install -m 0755 ${WORKDIR}/ipv4-advanced-route.sh ${D}${bindir}

    install -d -m 0755 ${D}/etc/sysctl.d
    echo "net.ipv4.conf.all.arp_ignore=1" >> ${D}/etc/sysctl.d/99-network.conf
    echo "net.ipv4.conf.default.arp_ignore=1" >> ${D}/etc/sysctl.d/99-network.conf

    echo "net.ipv4.tcp_timestamps=0" >> ${D}/etc/sysctl.d/99-network.conf
}

EXTRA_OEMESON:append = " -Dpersist-mac=true"

EXTRA_OEMESON:append = " -Ddefault-link-local-autoconf=ipv6"

EXTRA_OEMESON:append = " -Denable-advanced-route=true"

EXTRA_OEMESON:append = " -Denable-system-firewall=true"

# Uncomment to enable NCSI
# EXTRA_OEMESON:append = " -Denable-ncsi=true -Ddefault-ncsi-interface=eth3"
EXTRA_OEMESON:append = " -Dncsi-keep-phy-link-up=false"

EXTRA_OEMESON:append = " -Dncsi-flow-control=false"

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.GARPControl.service"
