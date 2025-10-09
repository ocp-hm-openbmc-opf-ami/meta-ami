# Sync to the latest x86-power-control. We can remove it after rebasing OpenBMC.
#SRCREV = "05e8ea8e3c834f2bd029647930dd8c139486bada"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://0002-Removed-SIO_POWER_GOOD-and-IdButton.patch \
	    file://0004-Updating-PowerState-currentHostState.patch \
	    file://0001-Removed-NMI-Button.patch \
           "

