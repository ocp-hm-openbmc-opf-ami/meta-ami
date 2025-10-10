FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

PROVIDES += "virtual/kernel"

require linux-onetree.inc

LINUX_VERSION = "6.6.100"

KERNEL_VERSION_SANITY_SKIP="1"

EXTRA_OEMAKE += "KCFLAGS=-DCONFIG_I3C_MCTP_HELPERS"

KBRANCH = "ocp"
KSRC = "git://git.ami.com/core/ami-bmc/base-tech/linux-lf.git;protocol=https;branch=${KBRANCH}"

# Include this as a comment only for downstream auto-bump
# SRC_URI = "git://git@github.com/intel-bmc/os.linux.kernel.openbmc.linux.git;protocol=ssh;branch=dev-6.1-intel"
SRCREV = "b12ab38770c3afc3cf0ba5ee888fe74127396eef"

SRC_URI:append = "${KSRC}"

do_compile:prepend(){
   # device tree compiler flags
   export DTC_FLAGS=-@
}

SRC_URI += "file://dts-ami/ \
	    file://Enable_I3C.cfg \
	    file://eth_over_usb.cfg \
 	    file://nfs_cifs.cfg \
	    file://bootlogo.cfg \
	    file://Enable_i2c_slave.cfg \
	    file://iptables.cfg \
	    file://0001-MCTP-driver-memoryleak-fix.patch \
            file://0002-MCTP-coverity-issues.patch \
	    file://CVE-2025-21786.patch \
	    file://0003-Add-I2C-slave-mqueue-support.patch \
	    file://0004-Fix-I2C-Coverity-for-linux-onetree.patch \
	    file://0004-Fix-common-kernel-I2C-patch-error-in-OT-AMD.patch \
	    file://0005-Add-the-M-Hold-patch-and-I2C-Driver-change-from-INTEL.patch \
            "

SRC_CPLD_SPI = " file://cpld-spidev.cfg \
		file://0006-enable-spidev-in-driver-file.patch"
SRC_URI:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-fwupdate', SRC_CPLD_SPI,'', d)}"

SRC_URI_NM += "file://disable_nm_sensor.cfg \
               file://disable_smart.cfg \
               "
SRC_URI:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-intelsipack', '', SRC_URI_NM, d)}"

SRC_USB_Gadget_Device = " file://USB-Port-B-as-Gadget-Device.cfg \
                        "

SRC_USB_HOST_Controller = " file://USB-Port-B-as-HOST-Controller.cfg "
SRC_URI:append = "${@bb.utils.contains('USB_Port_B_Function', 'Gadget-Device', SRC_USB_Gadget_Device, SRC_USB_HOST_Controller, d)}"

NETWORK_BONDING_SRC_URI += "file://bond.cfg \
                           "
SRC_URI += "${@bb.utils.contains('ENABLE_BONDING', 'network-bond', NETWORK_BONDING_SRC_URI,'', d)}"

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
