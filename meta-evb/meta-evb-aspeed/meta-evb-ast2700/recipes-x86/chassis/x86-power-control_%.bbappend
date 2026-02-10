# Sync to the latest x86-power-control. We can remove it after rebasing OpenBMC.
#SRCREV = "05e8ea8e3c834f2bd029647930dd8c139486bada"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://0001-Removed-NMI-SIO_PWR_GOOD-ID_BUTTON.patch \
           "

