FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://nfs.cfg \
            file://usb-eth.cfg \
            file://0001-USB-Ethernet-Gadget-Host-Interface.patch \
            file://0002-Fixed-compilation-error-on-USB-gadget.patch \
            file://0011-Enable-Threshold-Attributes-for-Core-temperature-sen.patch \
            file://0001-Fix-virtual-USB-hub-not-working-for-evb-ast2600.patch \
            file://0001-Upstream-aspeed-video.c-driver-from-ASPEED-SDK-v08.05.patch \
            file://jtag-fragment.cfg \
            file://0002-Added-jtag-aspeed-internal-driver.patch \
	    file://0003-Fix-incorrect-MAC-address-in-RNDIS-driver.patch \
           "

NON_PFR_SRC_URI_AMI = "file://0012-Add-new-layout-as-per-AMI-requirements.patch"

SRC_URI += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '',NON_PFR_SRC_URI_AMI, d)}"

SRC_URI_ASD = "file://0013-fix-ASD-jtag-driver-works-abnormally.patch"

SRC_URI:append = " ${@bb.utils.contains('IMAGE_INSTALL', 'at-scale-debug', SRC_URI_ASD, '' , d)}"

SRC_URI:append = " ${@bb.utils.contains('IMAGE_INSTALL', 'cpld-tool', SRC_URI_NON_PFR_CPLD , '' , d)}"

SRC_URI_NON_PFR_DUAL:append = "file://0013-Added-dts-configuration-for-dual-image-support.patch \
                              "
SRC_URI:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'dual-image', SRC_URI_NON_PFR_DUAL,'', d)}"
