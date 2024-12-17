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
        file://0042-Implement-Netlink-for-NCSI-Flow-Control.patch \
        file://0053-Fix-send-hid-data-will-halt-on-hid-queue.patch \
	file://0054-Add-i2c-slave-mqueue-support.patch \
	file://Enable_i2c_slave.cfg \
	file://0054-I2C-Mux-Hold-support.patch \
        file://0001-aspeed-video-enable-partial-jpeg-capture-support.patch \
        file://0055-Fix-usb-gadget-mass-storage-miss-stats-property.patch \
        file://0042-Fix-NCSI-FW-Name-Out-of-Range.patch \
        file://0038-Fix-probe-regression-for-ASPEED-UDC.patch \
	file://iptables.cfg \
	file://0056-quick-fix-for-raw-I2C-type-registration.patch \
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

SRC_URI_NM += "file://disable_nm_sensor.cfg \
               file://disable_smart.cfg \
               "
SRC_URI:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'nm-features', '', SRC_URI_NM, d)}"

#SRC_BIOS = "file://0020-bios-patch-to-enable-pnor-mtd.patch "
#
#SRC_URI:append:intel-ast2600  = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'bios-update', SRC_BIOS,'', d)}"
#

SRC_URI:append:intel-ast2600 = "file://0001-Ported-PECI-driver-support-from-INTEL-AMI.patch \
                                file://0002-Ported-HWMON-driver-changes-from-INTEL-AMI.patch \
                                file://0049-Fix-for-PECI-and-PMBUS-Errors.patch \
				file://Enable_MMBI.cfg \
                                file://0052-Fix-for-nm-cap-sensor.patch \
				"

SRC_ASPEED_MCTP_DRV = "file://0037-Clean-Intel-MCTP-over-PCIe-driver.patch \
                       file://0038-Add-ASPEED-MCTP-over-PCIe-driver.patch \
                      "

SRC_ASPEED_MCTP_DRV:append:intel-ast2600 = "file://0039-Fix-peci-for-ASPEED-MCTP-over-PCIe-driver.patch "
SRC_ASPEED_MCTP_DRV:append:evb-ast2600 = "file://0040-Add-dma-pool-for-EVB-MCTP-over-PCIe-driver.patch \"
SRC_URI:append= "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'use-lfmctp', SRC_ASPEED_MCTP_DRV,'', d)}"

SRC_USB_Gadget_Device = " file://0037-Enable-USB-Port-B-as-gadget-device.patch \
                          file://USB-Port-B-as-Gadget-Device.cfg \
                        "
SRC_USB_HOST_Controller = " file://USB-Port-B-as-HOST-Controller.cfg"
SRC_URI:append = "${@bb.utils.contains('USB_Port_B_Function', 'Gadget-Device', SRC_USB_Gadget_Device, SRC_USB_HOST_Controller, d)}"


#SRC_URI_IPMI_BT = "file://ipmi_bt.cfg \
#                   file://0037-IPMI-BT-Driver-Enable.patch \
#                   "
#SRC_URI:append:evb-ast2600 = "${@bb.utils.contains('IPMI_BT_SUPPORT', 'ipmi-bt-enable', SRC_URI_IPMI_BT, '', d)}"

SRC_URI_BHS:append = "  file://0054-Updating-VW_GPIO_DIR-register.patch \
                        file://enable_vw_gpio.cfg \
                     "
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', SRC_URI_BHS, '', d)}"

NETWORK_BONDING_SRC_URI += "file://bond.cfg \
                            file://0055-Ported-Network-Change-for-IPv6-Dynamic-Router-Command.patch \
                           "
SRC_URI += "${@bb.utils.contains('ENABLE_BONDING', 'network-bond', NETWORK_BONDING_SRC_URI,'', d)}"

##############
# PFR SUPPORT
##############
SRC_URI_BHS_PFR128 = "file://0056-PFR-BHS-128MB-Support.patch "
SRC_URI_BHS_PFR256 = "file://0056-PFR-BHS-256MB-Support.patch "
SRC_URI_BHS_PFR_CONFIG = "${@bb.utils.contains('PFR_CONFIG', 'pfr-256', SRC_URI_BHS_PFR256, SRC_URI_BHS_PFR128, d)}"
SRC_URI_BHS_PFR = "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', SRC_URI_BHS_PFR_CONFIG, '', d)}"
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', SRC_URI_BHS_PFR, '', d)}"


# Replacing existing kernel_do_install() with the fix from commit, https://git.yoctoproject.org/poky/commit/meta/classes-recipe/kernel.bbclass?h=styhead&id=5533d33d1e3b9be299230530c8e6ac6d0968631f
# This function can be removed in next LF sync
# 
kernel_do_install() {
	#
	# First install the modules
	#
	unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS MACHINE
	if (grep -q -i -e '^CONFIG_MODULES=y$' .config); then
		oe_runmake DEPMOD=echo MODLIB=${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION} INSTALL_FW_PATH=${D}${nonarch_base_libdir}/firmware modules_install
		rm -f "${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/build"
		rm -f "${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/source"
		# Remove empty module directories to prevent QA issues
		[ -d "${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/kernel" ] && find "${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/kernel" -type d -empty -delete
	else
		bbnote "no modules to install"
	fi

	#
	# Install various kernel output (zImage, map file, config, module support files)
	#
	install -d ${D}/${KERNEL_IMAGEDEST}

	#
	# When including an initramfs bundle inside a FIT image, the fitImage is created after the install task
	# by do_assemble_fitimage_initramfs.
	# This happens after the generation of the initramfs bundle (done by do_bundle_initramfs).
	# So, at the level of the install task we should not try to install the fitImage. fitImage is still not
	# generated yet.
	# After the generation of the fitImage, the deploy task copies the fitImage from the build directory to
	# the deploy folder.
	#

	for imageType in ${KERNEL_IMAGETYPES} ; do
		if [ $imageType != "fitImage" ] || [ "${INITRAMFS_IMAGE_BUNDLE}" != "1" ] ; then
			install -m 0644 ${KERNEL_OUTPUT_DIR}/$imageType ${D}/${KERNEL_IMAGEDEST}/$imageType-${KERNEL_VERSION}
		fi
	done

	install -m 0644 System.map ${D}/${KERNEL_IMAGEDEST}/System.map-${KERNEL_VERSION}
	install -m 0644 .config ${D}/${KERNEL_IMAGEDEST}/config-${KERNEL_VERSION}
	install -m 0644 vmlinux ${D}/${KERNEL_IMAGEDEST}/vmlinux-${KERNEL_VERSION}
	! [ -e Module.symvers ] || install -m 0644 Module.symvers ${D}/${KERNEL_IMAGEDEST}/Module.symvers-${KERNEL_VERSION}

}
