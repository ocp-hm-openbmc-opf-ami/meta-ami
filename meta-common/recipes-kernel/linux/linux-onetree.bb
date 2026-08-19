FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

PROVIDES += "virtual/kernel"

require linux-onetree.inc

LINUX_VERSION = "6.6.100"

KERNEL_VERSION_SANITY_SKIP = "1"

EXTRA_OEMAKE += "KCFLAGS=-DCONFIG_I3C_MCTP_HELPERS"

#KSRC = "git://git@github.com/ocp-hm-openbmc-opf-ami/linux.git;protocol=https;branch=onetree-dev-6.6"

# Include this as a comment only for downstream auto-bump
# SRC_URI = "git://git@github.com/intel-bmc/os.linux.kernel.openbmc.linux.git;protocol=ssh;branch=dev-6.1-intel"
SRC_URI:append = "git://git@github.com/ocp-hm-openbmc-opf-ami/linux.git;protocol=https;branch=onetree-dev-6.6 "

# KBRANCH is added for devtool to checkout to the same branch as the linux-lf branch. This variable is only used by the devtool utility and must be updated whenever the linux-lf branch changes.
KBRANCH = "onetree-dev-6.6"

KBUILD_CFLAGS += "-ffile-prefix-map=${WORKDIR}=/usr/src/debug/${PN}/${PV}"
KBUILD_CFLAGS += "-ffile-prefix-map=${B}=/usr/src/debug/${PN}/${PV}"
SRCREV = "cf0936d0e6ede13afd003565574ae53bcca8ef4f"


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
	    file://CVE-2025-21786.patch \
	    file://0003-Add-I2C-slave-mqueue-support.patch \
	    file://0004-Fix-I2C-Coverity-for-linux-onetree.patch \
	    file://0004-Fix-common-kernel-I2C-patch-error-in-OT-AMD.patch \
	    file://0005-Add-the-M-Hold-patch-and-I2C-Driver-change-from-INTEL.patch \
	    file://CVE-2025-38335.patch \
	    file://CVE-2025-38622.patch \
	    file://CVE-2025-38653.patch \
	    file://CVE-2025-38572.patch \
	    file://CVE-2025-3857.patch \
	    file://CVE-2025-38566.patch \
            file://CVE-2025-38639.patch \
	    file://CVE-2025-38670.patch \
	    file://CVE-2025-38555.patch \
	    file://CVE-2025-38565.patch \
	    file://CVE-2025-38563.patch \
            file://CVE-2025-38694.patch \
            file://CVE-2025-38725.patch \
            file://CVE-2025-38716.patch \
            file://CVE-2025-38707.patch \
            file://CVE-2025-38685.patch \
            file://CVE-2025-38693.patch \
            file://CVE-2025-38691.patch \
            file://CVE-2025-38728.patch \
            file://CVE-2025-38688.patch \
            file://CVE-2025-39711.patch \
            file://CVE-2025-39715.patch \
            file://CVE-2025-39713.patch \
            file://CVE-2025-39675.patch \
            file://CVE-2025-39693.patch \
            file://CVE-2025-39691.patch \
            file://CVE-2025-38732.patch \
            file://CVE-2025-39718.patch \
            file://CVE-2025-39703.patch \
            file://CVE-2025-39692.patch \
            file://CVE-2025-38734.patch \
            file://CVE-2025-39730.patch \
            file://CVE-2025-39751.patch \
            file://CVE-2025-39776.patch \
            file://CVE-2025-39835.patch \
            file://CVE-2025-39808.patch \
            file://CVE-2025-39824.patch \
            file://CVE-2025-39828.patch \
            file://CVE-2025-39823.patch \
            file://CVE-2025-39846.patch \
            file://CVE-2025-39865.patch \
            file://CVE-2025-39864.patch \
            file://CVE-2025-39863.patch \
            file://CVE-2025-39860.patch \
            file://CVE-2025-39857.patch \
            file://CVE-2025-39849.patch \
            file://CVE-2025-39838.patch \
            file://CVE-2025-39839.patch \
            file://CVE-2025-39848.patch \
            file://CVE-2025-39873.patch \
            file://CVE-2025-39881.patch \
            file://CVE-2025-39877.patch \
            file://CVE-2025-39880.patch \
	    file://CVE-2025-39827.patch \
	    file://CVE-2025-39826.patch \
	    file://CVE-2025-38632.patch \
            file://CVE-2025-38681.patch \
            file://CVE-2025-38701.patch \
            file://CVE-2025-38702.patch \
            file://CVE-2025-38709.patch \
            file://CVE-2025-39689.patch \
            file://CVE-2025-39724.patch \
            file://CVE-2025-38721.patch \
            file://CVE-2025-39683.patch \
            file://CVE-2025-39697.patch \
            file://CVE-2025-38677.patch \
            file://CVE-2025-39749.patch \
            file://CVE-2025-39788.patch \
            file://CVE-2025-39866.patch \
            file://CVE-2025-39944.patch \
            file://CVE-2025-38680.patch \
            file://CVE-2025-39757.patch \
            file://CVE-2025-39790.patch \
            file://CVE-2025-39869.patch \
            file://CVE-2025-39945.patch \
            file://CVE-2025-39685.patch \
            file://CVE-2025-39759.patch \
            file://CVE-2025-39806.patch \
            file://CVE-2025-39870.patch \
            file://CVE-2025-39687.patch \
            file://CVE-2025-39760.patch \
            file://CVE-2025-39817.patch \
            file://CVE-2025-39883.patch \
            file://CVE-2025-39738.patch \
            file://CVE-2025-39766.patch \
            file://CVE-2025-39841.patch \
            file://CVE-2025-39911.patch \
            file://CVE-2025-39743.patch \
            file://CVE-2025-39783.patch \
            file://CVE-2025-39853.patch \
            file://CVE-2025-39913.patch \
            file://CVE-2025-40129.patch \
            file://CVE-2025-71120.patch \
            file://CVE-2025-38617.patch \
            file://CVE-2025-39782.patch \
            file://CVE-2025-39744.patch \
            file://CVE-2025-39795.patch \
            file://CVE-2025-39798.patch \
            file://CVE-2025-39813.patch \
            file://CVE-2025-39825.patch \
            file://CVE-2025-39819.patch \
            file://CVE-2025-39844.patch \
            file://CVE-2025-39843.patch \
            file://CVE-2025-39770.patch \
            file://CVE-2025-39914.patch \
            file://CVE-2025-39902.patch \
            file://CVE-2025-39953.patch \
            file://CVE-2025-39931.patch \
            file://CVE-2025-38588.patch \
            file://CVE-2025-38587.patch \
            file://CVE-2025-38727.patch \
            file://CVE-2026-23398.patch \
            file://CVE-2026-23397.patch \
            file://CVE-2026-31414.patch \
            file://CVE-2026-31448.patch \
            file://CVE-2026-31685.patch \
            file://CVE-2026-43038.patch \
            file://CVE-2026-43071.patch \
            file://CVE-2026-43186.patch \
            file://CVE-2026-43341.patch \
            file://CVE-2026-43383.patch \
            file://CVE-2026-46185.patch \
            file://CVE-2026-46195.patch \
            file://CVE-2026-46115.patch \
            file://CVE-2025-68372.patch \
            file://CVE-2025-68237.patch \
            file://CVE-2025-68366.patch \
            file://CVE-2025-71162.patch \
            file://CVE-2026-23099.patch \
            file://CVE-2026-31473.patch \
            file://CVE-2026-43278.patch \
            file://CVE-2026-46190.patch \
            file://CVE-2026-43441.patch \
            file://CVE-2026-45970.patch \
            file://CVE-2026-23447.patch \
            file://CVE-2026-23448.patch \
            file://CVE-2025-40030.patch \
            file://CVE-2026-31389.patch \
            file://CVE-2025-71197.patch \
            file://CVE-2025-71295.patch \
            file://CVE-2026-43074.patch \
            file://CVE-2026-31446.patch \
            file://CVE-2026-31449.patch \
            file://CVE-2026-31450.patch \
            file://CVE-2026-31452.patch \
            file://CVE-2026-31447.patch \
            file://CVE-2025-68349.patch \
            file://CVE-2026-46150.patch \
            file://CVE-2025-40271.patch \
            file://CVE-2025-40328.patch \
            file://CVE-2026-43215.patch \
            file://CVE-2026-46300.patch \
            file://CVE-2026-43284.patch \
            file://CVE-2026-43503.patch \
            file://CVE-2026-43099.patch \
            file://CVE-2026-46037.patch \
            file://CVE-2026-46015.patch \
            file://CVE-2026-45844.patch \
            file://CVE-2025-39955.patch \
            file://CVE-2026-43339.patch \
            file://CVE-2026-43501.patch \
            file://CVE-2026-31680.patch \
            file://CVE-2026-43040.patch \
            file://CVE-2026-31674.patch \
            file://CVE-2026-43027.patch \
            file://CVE-2026-23458.patch \
            file://CVE-2026-31407.patch \
            file://CVE-2026-43329.patch \
            file://CVE-2026-23111.patch \
            file://CVE-2026-23231.patch \
            file://CVE-2026-23272.patch \
            file://CVE-2026-23392.patch \
            file://CVE-2026-43060.patch \
            file://CVE-2026-43453.patch \
            file://CVE-2026-43028.patch \
            file://CVE-2026-43452.patch \
            file://CVE-2026-23274.patch \
            file://CVE-2026-43190.patch \
            file://CVE-2026-31504.patch \
            file://CVE-2026-31700.patch \
            file://CVE-2026-31675.patch \
            file://CVE-2026-31673.patch \
	    file://CVE-2026-31392.patch \
            file://CVE-2025-68219.patch \
            file://CVE-2026-43112.patch \
            file://CVE-2025-40099.patch \
            file://CVE-2026-31613.patch \
            file://CVE-2026-31708.patch \
            file://CVE-2026-43239.patch \
            file://CVE-2026-43362.patch \
            file://CVE-2026-23388.patch \
            file://CVE-2026-45860.patch \
            file://CVE-2026-31665.patch \
            file://CVE-2026-23449.patch \
            file://CVE-2026-43366.patch \
            file://CVE-2026-31525.patch \
            file://CVE-2026-23271.patch \
            file://CVE-2026-46173.patch \
            file://CVE-2025-39977.patch \
            file://CVE-2025-40178.patch \
            file://CVE-2026-31586.patch \
            file://CVE-2026-43336.patch \
            file://CVE-2026-45847.patch \
            file://CVE-2026-23343.patch \
            file://CVE-2026-43499.patch \
            file://CVE-2026-23340.patch \
            file://CVE-2026-43194.patch \
	    file://CVE-2026-23351.patch \
	    file://CVE-2025-68231.patch \
            file://CVE-2026-43350.patch \
            file://CVE-2026-46244.patch \
            file://CVE-2026-46266.patch \
            file://CVE-2026-46253.patch \
            file://CVE-2026-46259.patch \
            file://CVE-2026-46323.patch \
            file://CVE-2026-43025.patch \
            file://CVE-2025-40360.patch \
            file://CVE-2025-68282.patch \
            file://CVE-2026-31709.patch \
            file://CVE-2026-46333.patch \
            file://CVE-2026-31528.patch \
            file://CVE-2026-31431.patch \
            file://CVE-2026-43078.patch \
            file://CVE-2025-39990.patch \
            file://CVE-2026-23025.patch \
            file://CVE-2026-46242.patch \
            file://CVE-2026-45942.patch \
            file://Fix-crypto-compilation-issue.patch \
            file://CVE-2026-31677.patch \
            file://CVE-2026-43043.patch \
            file://CVE-2025-40080.patch \
            file://CVE-2026-46089.patch \
            file://CVE-2026-31689.patch \
            file://CVE-2026-23471.patch \
            file://CVE-2026-31770.patch \
            file://CVE-2025-40134.patch \
            file://CVE-2025-40197.patch \
            file://CVE-2026-45865.patch \
            file://CVE-2025-40094.patch \
            file://CVE-2026-31412.patch \
            file://CVE-2026-43343.patch \
            file://CVE-2026-31728.patch \
            file://CVE-2026-43066.patch \
            file://CVE-2026-31451.patch \
            file://CVE-2025-68264.patch \
            file://CVE-2025-68261.patch \
            file://CVE-2025-40167.patch \
            file://CVE-2026-45920.patch \
            file://CVE-2025-40190.patch \
            file://CVE-2026-46094.patch \
            file://CVE-2025-68820.patch \
            file://CVE-2026-46046.patch \
            file://CVE-2026-23038-23047.patch \
            file://CVE-2025-68764.patch \
            file://CVE-2025-68185.patch \
            file://CVE-2025-40237.patch \
            file://CVE-2025-40103.patch \
            file://CVE-2026-23205.patch \
            file://CVE-2026-31693.patch \
            file://CVE-2025-40052.patch \
            file://CVE-2025-40320.patch \
            file://CVE-2026-43484.patch \
            file://CVE-2025-68814.patch \
            file://CVE-2025-71149.patch \
            file://CVE-2026-23473.patch \
            file://CVE-2026-45957.patch \
            file://CVE-2026-45919.patch \
            file://CVE-2025-68173.patch \
            file://CVE-2026-22977.patch \
            file://CVE-2026-23010.patch \
            file://CVE-2026-23442.patch \
            file://CVE-2026-23124.patch \
            file://CVE-2026-23139.patch \
            file://CVE-2026-45873.patch \
            file://CVE-2026-43024.patch \
            file://CVE-2025-71160.patch \
            file://CVE-2025-40109.patch \
            file://CVE-2025-71161.patch \
            file://CVE-2026-43211.patch \
            file://CVE-2026-45997.patch \
            file://CVE-2026-46083.patch \
            file://CVE-2026-31721.patch \
            file://CVE-2025-40179.patch \
            file://CVE-2026-43342.patch \
            file://CVE-2025-68288.patch \
            file://CVE-2025-40323.patch \
            file://CVE-2026-43288.patch \
            file://CVE-2025-40198.patch \
            file://CVE-2025-68794.patch \
            file://CVE-2026-43124.patch \
            file://CVE-2026-23230.patch \
            file://CVE-2025-71239.patch \
            file://CVE-2026-23113.patch \
            file://CVE-2026-31555.patch \
            file://CVE-2025-40201.patch \
            file://CVE-2025-68214.patch \
            file://CVE-2025-40021.patch \
            file://CVE-2025-71125.patch \
            file://CVE-2026-23097.patch \
            file://CVE-2025-40183.patch \
            file://CVE-2026-45886.patch \
            file://CVE-2025-68363.patch \
            file://CVE-2025-40078.patch \
            file://CVE-2026-46132.patch \
            file://CVE-2026-23302.patch \
            file://CVE-2025-39980.patch \
            file://CVE-2026-23300.patch \
            file://CVE-2026-23304.patch \
            file://CVE-2026-31428.patch \
            file://CVE-2026-31416.patch \
            file://CVE-2026-43085.patch \
            file://CVE-2026-43451.patch \
            file://CVE-2026-31424.patch \
            file://CVE-2025-40214.patch \
            file://CVE-2026-43428.patch \
            file://CVE-2025-40095.patch \
            file://CVE-2025-68241.patch \
            file://CVE-2025-40206.patch \
            file://CVE-2025-68245.patch \
            file://CVE-2026-46130.patch \
            file://CVE-2026-45859.patch \
            file://CVE-2026-23004.patch \
            file://CVE-2025-39964.patch \
            file://CVE-2025-68206.patch \
            file://CVE-2026-45905.patch \
            file://CVE-2025-40125.patch \
            file://CVE-2025-68756.patch \
            file://CVE-2026-23101.patch \
            file://CVE-2026-31737.patch \
            file://CVE-2026-23368.patch \
            file://CVE-2025-68312.patch \
            file://CVE-2025-40070.patch \
            file://CVE-2025-40105.patch \
            file://CVE-2025-38614.patch \
            file://CVE-2026-45912.patch \
            file://CVE-2025-68172.patch \
            file://CVE-2026-45948.patch \
            file://CVE-2026-45985.patch \
            file://CVE-2026-45899.patch \
            file://CVE-2025-68788.patch \
            file://CVE-2026-46040.patch \
            file://CVE-2026-23303.patch \
            file://CVE-2025-40268.patch \
            file://CVE-2025-71151.patch \
            file://CVE-2026-31614.patch \
            file://CVE-2025-39975.patch \
            file://CVE-2026-46155.patch \
            file://CVE-2024-14027.patch \
            file://CVE-2026-23138.patch \
            file://CVE-2026-31495.patch \
            file://CVE-2026-43439.patch \
            file://CVE-2026-43472.patch \
            file://CVE-2025-40341.patch \
            file://CVE-2025-40042.patch \
            file://CVE-2026-46196.patch \
            file://CVE-2026-23168.patch \
            file://CVE-2026-23254.patch \
            file://CVE-2026-23255.patch \
            file://CVE-2026-31429.patch \
            file://CVE-2026-22979.patch \
            file://CVE-2025-71148.patch \
            file://CVE-2025-68775.patch \
            file://CVE-2026-31415.patch \
            file://CVE-2026-45930.patch \
            file://CVE-2026-43455.patch \
            file://CVE-2026-46101.patch \
            file://CVE-2026-31681.patch \
            file://CVE-2025-40164.patch \
            file://CVE-2025-40093.patch \
            file://CVE-2026-45858.patch \
            file://CVE-2026-23053.patch \
            file://CVE-2025-68295.patch \
            file://CVE-2026-46106.patch \
            file://CVE-2026-45841.patch \
            file://CVE-2026-43026.patch \
            file://CVE-2025-68795.patch \
            file://CVE-2026-23047.patch \
            file://CVE-2026-45892.patch \
            "

# Include the below cfg file to get the proper mounting of the SD card partitions in Slot 1.
#SRC_URI += " file://enable_regulators_SDcard.cfg \"
# However the power operation gpio pins gets conflict with the voltage regulator pins.
# So after enabling it adjust and handle the power control gpio pins based on the platform configurations.

SRC_CPLD_SPI = " file://cpld-spidev.cfg \
                 file://0006-enable-spidev-in-driver-file.patch \
               "
SRC_URI:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-fwupdate', SRC_CPLD_SPI,'', d)}"

SRC_IPMI_SSIF = " file://0006-Add-SSIF-and-SBMR-support.patch \
                "
SRC_URI:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-ipmi-ssif', SRC_IPMI_SSIF,'', d)}"

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

SRC_URI:append = " ${@bb.utils.contains('ENABLE_COMMUNITY_MCTP_KERNEL_MODE', '1', ' file://Enable_MCTP_vdm.cfg ', '', d)}"

# ABR mode detection patch for AST2600
SRC_URI_ABR_PATCH = "file://0001-spi-aspeed-Add-ABR-mode-detection-support-for-AST260.patch"

# Apply to evb-ast2600
SRC_URI:append:evb-ast2600 = " \
    ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-hw-failsafe-boot', \
        '${SRC_URI_ABR_PATCH}', '', d)} \
"

# Apply to intel-ast2600
SRC_URI:append:intel-ast2600 = " \
    ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-hw-failsafe-boot', \
        '${SRC_URI_ABR_PATCH}', '', d)} \
"

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
