require conf/machine/include/imx95.inc

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://0001-openbmc-add-support-for-imx95-frdm.patch"
SRC_URI += "file://imx_openbmc_defconfig"
SRC_URI += " \
            file://0001-PCIe-patch-for-new-linux.patch \
            file://0002-PCIe-EP-based-changes.patch \
            file://0003-Change-PCIe-EP-device-class-to-Display-and-enumnerat.patch \
            file://0004-MAP-DPU95-registers-to-BAR4-and-increase-size-of-BAR.patch \
            file://0005-Added_pci_rom_support.patch \
            file://0006-PCI-endpoint-pci-epf-test-Add-VRAM-streaming-support.patch \
            file://0007-Add-character-device-interface-for-PCIe-framebuffer-.patch \
            file://0008-Add_dynamic_mode_support.patch \
            file://0009-Increase-vram-to-32MB-and-Switch-to-io_remap_pfn_ran.patch \
            file://0010-drm-imx-dpu95-add-reserved-VRAM-support-and-update-m.patch \
            file://0011-drm-imx-dpu95-add-STRIDE_OVERRIDE-plane-property.patch \
 "


S = "${WORKDIR}/git"

SRC_URI += "file://disable-console_fb.cfg"
KERNEL_CONFIG_FRAGMENTS += "disable-console_fb.cfg"


# Copy defconfig into kernel source before metadata check
do_kernel_metadata:prepend() {
    cp ${UNPACKDIR}/imx_openbmc_defconfig ${S}/arch/arm64/configs/
}

KERNEL_DEVICETREE:append = " freescale/imx95-15x15-frdm-bmc.dtb"
KERNEL_DEVICETREE:append = " freescale/imx95-19x19-evk-ep-adv7535.dtb"
