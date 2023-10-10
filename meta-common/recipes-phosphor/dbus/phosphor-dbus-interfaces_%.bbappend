FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-dbus-interfaces.git;branch=main;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "d04c1a17735f18c042b2ce32ab2f6574d6ec3418"

SRC_URI += "file://0001-ARP-Control-property.patch\
	    file://0003-ARP-VLAN-YAML.patch \
            file://0036-EnhancedPasswordPolicy.patch \
	    file://0005-Add-Bootstrap-credential-support.patch \
            file://0006-Add-Diag-Arugment-in-Boot-Mode-Interface.patch \
            file://0008-Add-Prefix-Length-at-Neighbor.patch \
            file://0009-Implement-EIP-741000.-Implement-DDNS-Nsupdate-Featur.patch \
            file://0010-Add-DBus-Property-IPv4-IPv6-Enabled-Disabled-And-Error-Handling.patch \
            file://0010-Added-TimeOut-for-managers.patch \
	    file://0012-passwordChangeRequired.patch \
	    file://0012-Certificate-dbus-renew-rekey.patch \
            file://0013-Add-DBus-properties-to-Save-IPv6-Static-Router-Control.patch \
            file://0015-Add-Index-property-for-IPAddress-Object.patch \
	    "
EXTRA_OEMESON += "-Ddata_com_ami=true"
EXTRA_OEMESON += "-Ddata_org_open_power=true"

NETWORK_BONDING_SRC_URI += "file://0014-Support-Network-Bonding.patch"

SRC_URI += "${@bb.utils.contains('ENABLE_BONDING', 'network-bond', NETWORK_BONDING_SRC_URI,'', d)}"

