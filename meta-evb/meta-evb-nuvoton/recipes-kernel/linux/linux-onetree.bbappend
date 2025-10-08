FILESEXTRAPATHS:prepend := "${THISDIR}/linux-onetree:"

SRC_URI:append:nuvoton = " file://enable-emc.cfg"
SRC_URI:append:nuvoton:df-obmc-static-norootfs = " file://enable-spinor-ubifs.cfg"

SRC_URI:append:nuvoton = " file://iptables.cfg"
SRC_URI:append:nuvoton = " file://bond.cfg"
SRC_URI:append:nuvoton = " file://iproute.cfg"
SRC_URI:append:nuvoton = " file://vlan.cfg"
SRC_URI:append:nuvoton = " file://disable_sgpio.cfg"

