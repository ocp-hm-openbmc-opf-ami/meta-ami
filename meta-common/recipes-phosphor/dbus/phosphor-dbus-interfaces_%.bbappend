FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-ARP-Control-property.patch\
	    file://0002-Add-PreviousCycleCount-and-CurrentCycleCount-PostCod.patch \
	    file://0003-ARP-VLAN-YAML.patch \
		file://0036-EnhancedPasswordPolicy.patch \
	    file://0005-Add-Bootstrap-credential-support.patch \
            file://0006-Add-Diag-Arugment-in-Boot-Mode-Interface.patch \
		"
