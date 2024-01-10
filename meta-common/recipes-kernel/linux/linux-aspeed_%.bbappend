FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://nfs.cfg \
            file://usb-eth.cfg \
            file://0001-USB-Ethernet-Gadget-Host-Interface.patch \
            file://0002-Fixed-compilation-error-on-USB-gadget.patch \
            file://0011-Enable-Threshold-Attributes-for-Core-temperature-sen.patch \
            file://0001-Fix-virtual-USB-hub-not-working-for-evb-ast2600.patch \
            file://0001-Upstream-aspeed-video.c-driver-from-ASPEED-SDK-v08.05.patch \
            file://0014-add-jtag-aspeed-internal-cpld-driver.patch \
	    file://0003-Fix-incorrect-MAC-address-in-RNDIS-driver.patch \
            file://0016-legacy-driver-support-for-pwm-driver.patch \
            file://0002-i3c-mctp-workaround-for-wrong-DCR-value.patch \
            file://0017-Add-write-public-key-in-image-support.patch \
            file://0018-Nm-sensor-Threshold-Support.patch \
            file://CVE-2023-31248.patch \
            file://CVE-2023-4147.patch \
            file://CVE-2023-35001.patch \
            file://CVE-2023-3269.patch \
            file://CVE-2023-4622.patch \
            file://CVE-2023-5717.patch \
            file://CVE-2023-31085.patch \
            file://CVE-2023-42754.patch \
            file://iptables.cfg \
           "

NON_PFR_SRC_URI_AMI = "file://0012-Add-new-layout-as-per-AMI-requirements.patch \
                       file://0019-Fix-for-JFFS2-issue-due-to-SPI-tx-bus-width.patch \
                      "

SRC_URI:append:intel-ast2600 = "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '',NON_PFR_SRC_URI_AMI, d)}"

SRC_URI_NON_PFR_DUAL:append:intel-ast2600 = "file://0013-Added-dts-configuration-for-dual-image-support.patch "
SRC_URI_NON_PFR_DUAL:append = "file://0024-add-fmc-ce0-ce1-acccess-support.patch "
SRC_URI_NON_PFR_DUAL:append:evb-ast2600  = "file://0025-add-dual-image-dts-support-for-evb.patch "
SRC_URI:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'dual-image', SRC_URI_NON_PFR_DUAL,'', d)}"

SRC_CPLD_JTAG = "file://jtag-fragment.cfg"

SRC_ASD_JTAG = "file://jtag-asd-fragment.cfg"

SRC_URI += "${@bb.utils.contains('IMAGE_INSTALL', 'at-scale-debug', SRC_ASD_JTAG, SRC_CPLD_JTAG, d)}"

NETWORK_BONDING_SRC_URI += "file://bond.cfg \
                            file://0017-Disable-Default-Network-Bonding.patch \
                           "
SRC_URI += "${@bb.utils.contains('ENABLE_BONDING', 'network-bond', NETWORK_BONDING_SRC_URI,'', d)}"

SRC_URI_NM += "file://disable_nm_sensor.cfg \
               file://disable_smart.cfg \
               "
SRC_URI:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'nm-features', '', SRC_URI_NM, d)}"

SRC_BIOS = "file://0020-bios-patch-to-enable-pnor-mtd.patch "

SRC_URI:append:intel-ast2600  = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'bios-update', SRC_BIOS,'', d)}"

SRC_CPLD_SPI = "file://cpld-spidev.cfg \
file://0021-Enable-spidev-for-spi2-for-cpld-upgrade-via-spi.patch \
"
SRC_URI:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'cpld-update', SRC_CPLD_SPI,'', d)}"

SRC_CPLD = " file://0019-Enabling-JTAG0-for-CPLD-update-using-jatg.patch \
file://0022-Enable-spidev-for-spi2-for-cpld-upgrade-via-spi-intel-dts.patch \
"
SRC_URI:append:intel-ast2600  = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'cpld-update', SRC_CPLD,'', d)}"

SRC_CPLD_EVB = "file://0023-Enable-spidev-for-spi2-for-cpld-upgrade-via-spi-evb-dts.patch "
SRC_URI:append:evb-ast2600  = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'cpld-update', SRC_CPLD_EVB,'', d)}"



