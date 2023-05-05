FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://nfs.cfg \
	    file://usb-eth.cfg \
	    file://0001-USB-Ethernet-Gadget-Host-Interface.patch \
	    file://0011-Enable-Threshold-Attributes-for-Core-temperature-sen.patch \
           "

