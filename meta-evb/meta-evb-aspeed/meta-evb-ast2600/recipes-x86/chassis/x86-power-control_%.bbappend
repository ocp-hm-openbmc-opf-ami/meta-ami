FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
	    file://0001-power-status-workaround.patch \
            file://0002-Removed-SIO_POWER_GOOD-and-IdButton.patch \
           "
