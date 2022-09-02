FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-ARP-Control-property.patch\
	    file://0002-Add-PreviousCycleCount-and-CurrentCycleCount-PostCod.patch \
	    file://0003-ARP-VLAN-YAML.patch"
