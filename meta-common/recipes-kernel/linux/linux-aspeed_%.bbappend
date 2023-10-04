FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://nfs.cfg \
            file://usb-eth.cfg \
            file://0001-USB-Ethernet-Gadget-Host-Interface.patch \
            file://0002-Fixed-compilation-error-on-USB-gadget.patch \
            file://0011-Enable-Threshold-Attributes-for-Core-temperature-sen.patch \
            file://0001-Fix-virtual-USB-hub-not-working-for-evb-ast2600.patch \
            file://0001-Upstream-aspeed-video.c-driver-from-ASPEED-SDK-v08.05.patch \
            file://jtag-fragment.cfg \
            file://0014-add-jtag-aspeed-internal-cpld-driver.patch \
	    file://0003-Fix-incorrect-MAC-address-in-RNDIS-driver.patch \
            file://0015-Adding-Threshols-support-for-NM-support.patch \
            file://0016-legacy-driver-support-for-pwm-driver.patch \
            file://0002-i3c-mctp-workaround-for-wrong-DCR-value.patch \
            file://0017-Add-write-public-key-in-image-support.patch \
           "

NON_PFR_SRC_URI_AMI = "file://0012-Add-new-layout-as-per-AMI-requirements.patch \
                      "

SRC_URI += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '',NON_PFR_SRC_URI_AMI, d)}"

SRC_URI_NON_PFR_DUAL:append = "file://0013-Added-dts-configuration-for-dual-image-support.patch \
                              "
SRC_URI:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'dual-image', SRC_URI_NON_PFR_DUAL,'', d)}"

NETWORK_BONDING_SRC_URI += "file://bond.cfg \
                            file://0017-Disable-Default-Network-Bonding.patch \
                           "
SRC_URI += "${@bb.utils.contains('ENABLE_BONDING', 'network-bond', NETWORK_BONDING_SRC_URI,'', d)}"

