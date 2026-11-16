FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

PROVIDES += "virtual/kernel"


LINUX_VERSION = "6.18.37"

KERNEL_VERSION_SANITY_SKIP = "1"

EXTRA_OEMAKE += "KCFLAGS=-DCONFIG_I3C_MCTP_HELPERS"

#KSRC = "git://git.ami.com/core/ami-bmc/base-tech/linux-lf.git;protocol=https;branch=onetree-dev-6.6"

# Include this as a comment only for downstream auto-bump
# SRC_URI = "git://git@github.com/intel-bmc/os.linux.kernel.openbmc.linux.git;protocol=ssh;branch=dev-6.1-intel"
SRC_URI = "git://git.ami.com/core/ami-bmc/base-tech/linux-lf.git;protocol=https;branch=onetree-dev-6.18 "

require linux-onetree.inc

# KBRANCH is added for devtool to checkout to the same branch as the linux-lf branch. This variable is only used by the devtool utility and must be updated whenever the linux-lf branch changes.
KBRANCH = "onetree-dev-6.18"

KBUILD_CFLAGS += "-ffile-prefix-map=${WORKDIR}=/usr/src/debug/${PN}/${PV}"
KBUILD_CFLAGS += "-ffile-prefix-map=${B}=/usr/src/debug/${PN}/${PV}"
SRCREV = "00ee738d91980defe834aa1f31825ad31909ce57"


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
            "

# Include the below cfg file to get the proper mounting of the SD card partitions in Slot 1.
#SRC_URI += " file://enable_regulators_SDcard.cfg \"
# However the power operation gpio pins gets conflict with the voltage regulator pins.
# So after enabling it adjust and handle the power control gpio pins based on the platform configurations.

SRC_URI_NM += "file://disable_nm_sensor.cfg \
               file://disable_smart.cfg \
               "
SRC_URI:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-intelsipack', '', SRC_URI_NM, d)}"

SRC_USB_Gadget_Device = " file://USB-Port-B-as-Gadget-Device.cfg \
                        "

SRC_USB_HOST_Controller = " file://USB-Port-B-as-HOST-Controller.cfg "
SRC_URI:append = "${@bb.utils.contains('USB_Port_B_Function', 'Gadget-Device', SRC_USB_Gadget_Device, SRC_USB_HOST_Controller, d)}"

NETWORK_BONDING_SRC_URI += " file://bond.cfg \
                           "
SRC_URI += "${@bb.utils.contains('ENABLE_BONDING', 'network-bond', NETWORK_BONDING_SRC_URI,'', d)}"

SRC_URI:append = " ${@bb.utils.contains('ENABLE_COMMUNITY_MCTP_KERNEL_MODE', '1', ' file://Enable_MCTP_vdm.cfg ', '', d)}"

do_configure:append(){
    if ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-ncsi-non-aen-support', 'true', 'false', d)}; then
       echo "CONFIG_NCSI_AMI_NON_AEN_SUPPORT=y" >> ${B}/.config
    fi

    if ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-ncsi-non-aen-support', 'true', 'false', d)}; then
       echo "CONFIG_NCSI_AMI_TIMER_INTERVAL_FOR_GET_LINK_STATUS=${NCSI_POLLING_INTERVAL}" >> ${B}/.config
    fi

    if ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-ncsi-manual-detect-support', 'true', 'false', d)}; then
       echo "CONFIG_NCSI_AMI_MANUAL_DETECT=y" >> ${B}/.config
    fi

    if ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-ncsi-async-reset-support', 'true', 'false', d)}; then
       echo "CONFIG_NCSI_AMI_ASYNC_RESET=y" >> ${B}/.config
    fi
}

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


SRC_URI += "file://CVE-2026-74608.patch"

SRC_URI += "file://CVE-2026-74616.patch"

SRC_URI += "file://CVE-2026-74705.patch"

SRC_URI += "file://CVE-2026-74746.patch"

SRC_URI += "file://CVE-2026-80589.patch"

SRC_URI += "file://CVE-2026-80603.patch"

SRC_URI += "file://CVE-2026-93207.patch"

SRC_URI += "file://CVE-2026-89634.patch"

SRC_URI += "file://CVE-2026-89541.patch"

SRC_URI += "file://CVE-2026-74327.patch"

SRC_URI += "file://CVE-2026-74566.patch"

SRC_URI += "file://CVE-2026-74331.patch"

SRC_URI += "file://CVE-2026-74329.patch"

SRC_URI += "file://CVE-2026-74308.patch"

SRC_URI += "file://CVE-2026-72379.patch"

SRC_URI += "file://CVE-2026-72396.patch"

SRC_URI += "file://CVE-2026-72349.patch"

SRC_URI += "file://CVE-2026-72256.patch"

SRC_URI += "file://CVE-2026-72218.patch"

SRC_URI += "file://CVE-2026-72219.patch"

SRC_URI += "file://CVE-2026-72132.patch"

SRC_URI += "file://CVE-2026-72155.patch"

SRC_URI += "file://CVE-2026-72106.patch"

SRC_URI += "file://CVE-2026-72096.patch"

SRC_URI += "file://CVE-2026-72068.patch"

SRC_URI += "file://CVE-2026-74683.patch"

SRC_URI += "file://CVE-2026-74694.patch"

SRC_URI += "file://CVE-2026-74657.patch"

SRC_URI += "file://CVE-2026-74673.patch"

SRC_URI += "file://CVE-2026-74619.patch"

SRC_URI += "file://CVE-2026-74636.patch"

SRC_URI += "file://CVE-2026-74599.patch"

SRC_URI += "file://CVE-2026-80660.patch"

SRC_URI += "file://CVE-2026-80636.patch"

SRC_URI += "file://CVE-2026-80744.patch"

SRC_URI += "file://CVE-2026-80742.patch"

SRC_URI += "file://CVE-2026-80733.patch"

SRC_URI += "file://CVE-2026-80730.patch"

SRC_URI += "file://CVE-2026-80906.patch"

SRC_URI += "file://CVE-2026-80876.patch"

SRC_URI += "file://CVE-2026-80824.patch"

SRC_URI += "file://CVE-2026-80830.patch"

SRC_URI += "file://CVE-2026-80837.patch"

SRC_URI += "file://CVE-2026-80793.patch"

SRC_URI += "file://CVE-2026-80808.patch"

SRC_URI += "file://CVE-2026-80792.patch"

SRC_URI += "file://CVE-2026-80781.patch"

SRC_URI += "file://CVE-2026-80918.patch"

SRC_URI += "file://CVE-2026-89765.patch"

SRC_URI += "file://CVE-2026-89756.patch"

SRC_URI += "file://CVE-2026-89753.patch"

SRC_URI += "file://CVE-2026-89749.patch"

SRC_URI += "file://CVE-2026-89710.patch"

SRC_URI += "file://CVE-2026-89640.patch"

SRC_URI += "file://CVE-2026-89595.patch"

SRC_URI += "file://CVE-2026-89550.patch"

SRC_URI += "file://CVE-2026-89551.patch"

SRC_URI += "file://CVE-2026-89548.patch"

SRC_URI += "file://CVE-2026-89549.patch"

SRC_URI += "file://CVE-2026-89547.patch"

SRC_URI += "file://CVE-2026-89540.patch"

SRC_URI += "file://CVE-2026-89538.patch"

SRC_URI += "file://CVE-2026-89515.patch"

SRC_URI += "file://CVE-2026-81007.patch"

SRC_URI += "file://CVE-2026-81002.patch"

SRC_URI += "file://CVE-2026-80963.patch"

SRC_URI += "file://CVE-2026-80977.patch"

SRC_URI += "file://CVE-2026-80952.patch"

SRC_URI += "file://CVE-2026-89998.patch"

SRC_URI += "file://CVE-2026-90203.patch"

SRC_URI += "file://CVE-2026-93046.patch"

SRC_URI += "file://CVE-2026-90062.patch"

SRC_URI += "file://CVE-2026-90003.patch"

SRC_URI += "file://CVE-2026-93189.patch"

SRC_URI += "file://CVE-2026-89997.patch"

SRC_URI += "file://CVE-2026-90329.patch"

SRC_URI += "file://CVE-2026-89823.patch"

SRC_URI += "file://CVE-2026-90102.patch"

SRC_URI += "file://CVE-2026-89542.patch"

SRC_URI += "file://CVE-2026-89536.patch"

SRC_URI += "file://CVE-2026-90103.patch"

SRC_URI += "file://CVE-2026-90063.patch"

SRC_URI += "file://CVE-2026-68461.patch"
SRC_URI += "file://CVE-2026-74256.patch"
SRC_URI += "file://CVE-2026-74567.patch"
SRC_URI += "file://CVE-2026-72110.patch"
SRC_URI += "file://CVE-2026-74359.patch"
SRC_URI += "file://CVE-2026-74579.patch"
SRC_URI += "file://CVE-2026-72225.patch"
SRC_URI += "file://CVE-2026-74471.patch"
SRC_URI += "file://CVE-2026-74714.patch"
SRC_URI += "file://CVE-2026-72250.patch"
SRC_URI += "file://CVE-2026-74550.patch"
SRC_URI += "file://CVE-2026-72172.patch"
SRC_URI += "file://CVE-2026-72502.patch"
SRC_URI += "file://CVE-2026-72067.patch"
SRC_URI += "file://CVE-2026-72247.patch"
SRC_URI += "file://CVE-2026-72400.patch"
SRC_URI += "file://CVE-2026-74289.patch"
SRC_URI += "file://CVE-2026-72419.patch"
SRC_URI += "file://CVE-2026-72347.patch"
SRC_URI += "file://CVE-2026-74582.patch"
SRC_URI += "file://CVE-2026-74519.patch"
SRC_URI += "file://CVE-2026-72444.patch"
SRC_URI += "file://CVE-2026-74288.patch"
SRC_URI += "file://CVE-2026-74662.patch"
SRC_URI += "file://CVE-2026-80725.patch"
SRC_URI += "file://CVE-2026-53362.patch"
SRC_URI += "file://CVE-2026-53366.patch"
SRC_URI += "file://CVE-2026-74726.patch"
SRC_URI += "file://CVE-2026-72252.patch"
SRC_URI += "file://CVE-2026-72350.patch"
SRC_URI += "file://CVE-2026-72310.patch"
SRC_URI += "file://CVE-2026-74564.patch"
SRC_URI += "file://CVE-2026-72102.patch"
SRC_URI += "file://CVE-2026-74270.patch"
SRC_URI += "file://CVE-2026-74330.patch"
SRC_URI += "file://CVE-2026-72066.patch"
SRC_URI += "file://CVE-2026-72254.patch"
SRC_URI += "file://CVE-2026-72255.patch"
SRC_URI += "file://CVE-2026-72487.patch"

SRC_URI += "file://CVE-2026-90049.patch"

SRC_URI += "file://CVE-2026-89786.patch"

SRC_URI += "file://CVE-2026-90235.patch"

SRC_URI += "file://CVE-2026-90151.patch"

SRC_URI += "file://CVE-2026-90110.patch"

SRC_URI += "file://CVE-2026-74630.patch"

SRC_URI += "file://CVE-2026-74594.patch"

SRC_URI += "file://CVE-2026-80718.patch"

SRC_URI += "file://CVE-2026-80677.patch"

SRC_URI += "file://CVE-2026-80646.patch"

SRC_URI += "file://CVE-2026-74696.patch"

SRC_URI += "file://CVE-2026-74656.patch"

SRC_URI += "file://CVE-2026-74668.patch"

SRC_URI += "file://CVE-2026-74667.patch"

SRC_URI += "file://CVE-2026-74666.patch"

SRC_URI += "file://CVE-2026-74624.patch"

SRC_URI += "file://CVE-2026-74606.patch"

SRC_URI += "file://CVE-2026-74601.patch"

SRC_URI += "file://CVE-2026-74598.patch"

SRC_URI += "file://CVE-2026-80578.patch"

SRC_URI += "file://CVE-2026-80664.patch"

SRC_URI += "file://CVE-2026-80590.patch"

SRC_URI += "file://CVE-2026-52915.patch"

SRC_URI += "file://CVE-2026-23278.patch"
SRC_URI += " file://0001-netfilter-nf_tables-fix-implicit-fallthrough.patch "

SRC_URI += "file://CVE-2026-72392.patch"
SRC_URI += "file://CVE-2026-80806.patch"
SRC_URI += "file://CVE-2026-68118.patch"
SRC_URI += "file://CVE-2026-74658.patch"
SRC_URI += "file://CVE-2026-74672.patch"
