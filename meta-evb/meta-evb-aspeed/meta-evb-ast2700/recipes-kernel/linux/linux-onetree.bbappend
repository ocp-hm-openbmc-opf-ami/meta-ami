FILESEXTRAPATHS:prepend := "${THISDIR}/linux-onetree:"

# remove obmc-phosphor-kernel-version class to avoid conflicts in setting localversion
KERNEL_CLASSES:remove = " obmc-phosphor-kernel-version"

DEPENDS += "lzop-native"
DEPENDS += "${@bb.utils.contains('MACHINE_FEATURES', 'ast-secure', 'aspeed-secure-config-native', '', d)}"

SRC_URI:append = " file://ipmi_ssif.cfg "
SRC_URI:append = " file://mtd_test.cfg "
SRC_URI:append = " file://crpyto_manager.cfg "
SRC_URI:append:spi-nor-ecc = " file://jffs2_writebuffer.cfg "
SRC_URI:append = " file://iptables.cfg "

SRC_URI:append = "  file://nfs_cifs.cfg "

SRC_URI:append = " file://iproute2.cfg "
SRC_URI:append = " file://iproute.cfg "
SRC_URI:append = " file://bond.cfg "
SRC_URI:append = " file://aspeed-g7/ "
SRC_URI:append = " file://0001-Fix-spi-driver-issue.patch " 

# RS-485: driver support lives in-tree behind CONFIG_SERIAL_8250_ASPEED_RS485.
# Enabled family-wide via MACHINE_FEATURES "onetree-rs485" (set in layer.conf); DTS in meta-ast2700.
SRC_URI:append = "${@bb.utils.contains('MACHINE_FEATURES', 'onetree-rs485', ' file://rs485.cfg ', '', d)}"

SRC_URI_AST2700_DUAL_IMAGE = "\
                                file://0001-Added-the-sysfs-file-for-Dual-Image-support-2700.patch \
				file://0001-Fixed-the-dula-image-booting-issue.patch \
				file://0001-spi-aspeed-smc-Add-ABR-boot-mode-detection-via-SCU-f.patch \
				file://0068-Fix-for-dual-image-hardware-failsafe-in-ast2700evb.patch \
			        file://0001-fix-the-abr-boot-mode-detection-in-dual-image.patch \
"

SRC_URI:append:ast2700-default = " ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image', d.getVar('SRC_URI_AST2700_DUAL_IMAGE'), '', d)}"

do_kernel_configme:prepend() {
    install -d ${S}/arch/arm64/configs
    cp ${UNPACKDIR}/aspeed-g7/aspeed_g7_defconfig ${S}/arch/arm64/configs/
}
