FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEPENDS += "nlohmann-json boost"
SRCREV = "33b4eaa734a32914d26b69ba92190bbe70272e05"

SRC_URI:append:evb-ast2600 = " file://0003-Adding-channel-specific-privilege-to-network.patch"
SRC_URI:append = " file://0001-ARP-Control.patch \
                    file://0002-VLAN-Priority.patch"


SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.GARPControl.service"

EXTRA_OEMESON:append = " -Dnic-ethtool=true"
EXTRA_OEMESON:append = " -Ddefault-ipv6-accept-ra=true"
EXTRA_OEMESON:append = " -Dhyp-nw-config=false"
