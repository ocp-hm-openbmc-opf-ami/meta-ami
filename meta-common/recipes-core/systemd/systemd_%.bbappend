FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-Support-DHCPv6-Transmission-Retransmission-Timing-Parameters.patch \
	    file://0002-Fix-to-update-DHCPv6-address-in-systemd-file.patch"


