FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0003-Ported-ADC-driver-changes-from-INTEL-AMI.patch \
	file://0004-Ported-USB-driver-changes-from-INTEL-AMI.patch \
	file://0005-Ported-WDT-driver-changes-from-INTEL-AMI.patch \
	file://0006-Ported-GPIO-driver-changes-from-INTEL-AMI.patch \
	file://0007-Ported-PWM-driver-changes-from-INTEL-AMI.patch \
	file://0008-Ported-MFD-driver-changes-from-INTEL-AMI.patch \
	file://0009-Ported-SPI-driver-changes-from-INTEL-AMI.patch \
	file://0010-Ported-JTAG-driver-changes-from-INTEL-AMI.patch \
	file://0011-Ported-UART-drivr-changes-from-INTEL-AMI.patch \
	file://0012-Ported-PINCTRL-driver-changes-from-INTEL-AMI.patch \
	file://0013-Ported-NETWORK-changes-from-INTEL-AMI.patch \
	file://0014-Ported-MCTP-driver-changes-from-INTEL-AMI.patch \
	file://0015-Ported-ESPI-driver-changes-from-INTEL-AMI.patch \
	file://0016-Ported-soc-aspeed-driver-chnages-from-INTEL-AMI.patch \
	file://0017-Ported-LPC-driver-changes-from-INTEl-AMI.patch \
	file://0018-Ported-I2C-driver-changes-from-INTEL-AMI.patch \
	file://0019-Ported-I3C-drivrr-changes-INTEL-AMI.patch \
	file://0020-Added-header-file-to-aspeed-espi-vw-module.patch \
	file://0021-Enable_I3C0_I3C4I3C5_controllers_for_evb.patch \
	file://0022-fix_i3c_node_create_issue.patch \
	file://Enable_I3C.cfg \
	file://0041-Add-write-public-key-in-image-support.patch \
	file://0050-Modify-IPMI-KCS-BT-Driver-for-Kernel_6.6.patch \
	file://0051-Add-bootlogo-support.patch \
	file://eth_over_usb.cfg \
	file://nfs_cifs.cfg \
	file://bootlogo.cfg \
        "

SRC_URI_NON_PFR_DUAL ?= ""

SRC_URI_NON_PFR_DUAL:append:intel-ast2600 = "file://0046-Added-dts-configuration-for-dual-image-support-for-intel.patch "

SRC_URI_NON_PFR_DUAL:append:evb-ast2600 = "file://0042-add-dual-image-dts-support-for-evb.patch"

SRC_URI:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'dual-image', SRC_URI_NON_PFR_DUAL,'', d)}"

SRC_URI_NON_PFR_SINGLE_SPI_ABR:append = "file://0047-add-hw-failsafe-boot-single-spi-abr-support-intel.patch "

SRC_URI:append:intel-ast2600 = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'single-spi-abr', SRC_URI_NON_PFR_SINGLE_SPI_ABR,'', d)}"

SRC_URI_NON_PFR_SINGLE_SPI_ABR_EVB:append = "file://0043-add-hw-failsafe-boot-single-spi-abr-support-for-evb.patch "

SRC_URI:append:evb-ast2600 = " ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'single-spi-abr', SRC_URI_NON_PFR_SINGLE_SPI_ABR_EVB,'', d)}"

SRC_CPLD_SPI = "file://cpld-spidev.cfg \
file://0048-Enable-spidev-for-spi2-for-cpld-upgrade-via-spi-inte.patch "

SRC_URI:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'cpld-update', SRC_CPLD_SPI,'', d)}"

SRC_CPLD = "file://0045-Intel-Enable-Jtag0-and-spidev-for-spi2-for-cpld-upgrade-vi.patch "
SRC_URI:append:intel-ast2600  = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'cpld-update', SRC_CPLD,'', d)}"

SRC_CPLD_EVB = "file://0044-Enable-spidev-for-spi2-and-jtag0-for-cpld-upgrade-vi.patch "
SRC_URI:append:evb-ast2600  = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'cpld-update', SRC_CPLD_EVB,'', d)}"


#NETWORK_BONDING_SRC_URI += "file://bond.cfg \
#                            file://0017-Disable-Default-Network-Bonding.patch \
#                           "
#SRC_URI += "${@bb.utils.contains('ENABLE_BONDING', 'network-bond', NETWORK_BONDING_SRC_URI,'', d)}"
#

SRC_URI_NM += "file://disable_nm_sensor.cfg \
               file://disable_smart.cfg \
               "
SRC_URI:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'nm-features', '', SRC_URI_NM, d)}"

#SRC_BIOS = "file://0020-bios-patch-to-enable-pnor-mtd.patch "
#
#SRC_URI:append:intel-ast2600  = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'bios-update', SRC_BIOS,'', d)}"
#

SRC_ASPEED_MCTP_DRV = "file://0037-Clean-Intel-MCTP-over-PCIe-driver.patch \
            file://0038-Add-ASPEED-MCTP-over-PCIe-driver.patch \
            file://0039-Fix-peci-for-ASPEED-MCTP-over-PCIe-driver.patch \
           "
SRC_ASPEED_MCTP_DRV:append:evb-ast2600 = "file://0040-Add-dma-pool-for-EVB-MCTP-over-PCIe-driver.patch \"
SRC_URI:append= "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'use-lfmctp', SRC_ASPEED_MCTP_DRV,'', d)}"

SRC_URI:append:intel-ast2600 = "file://0001-Ported-PECI-driver-support-from-INTEL-AMI.patch \
                                file://0002-Ported-HWMON-driver-changes-from-INTEL-AMI.patch \
                                file://0049-Fix-for-PECI-and-PMBUS-Errors.patch \
				file://Enable_MMBI.cfg \
                                file://0052-Fix-for-nm-cap-sensor.patch \
				"

SRC_USB_Gadget_Device = " file://0037-Enable-USB-Port-B-as-gadget-device.patch \
                          file://USB-Port-B-as-Gadget-Device.cfg \
                        "
SRC_USB_HOST_Controller = " file://USB-Port-B-as-HOST-Controller.cfg"
SRC_URI:append = "${@bb.utils.contains('USB_Port_B_Function', 'Gadget-Device', SRC_USB_Gadget_Device, SRC_USB_HOST_Controller, d)}"


#SRC_URI_IPMI_BT = "file://ipmi_bt.cfg \
#                   file://0037-IPMI-BT-Driver-Enable.patch \
#                   "
#SRC_URI:append:evb-ast2600 = "${@bb.utils.contains('IPMI_BT_SUPPORT', 'ipmi-bt-enable', SRC_URI_IPMI_BT, '', d)}"
