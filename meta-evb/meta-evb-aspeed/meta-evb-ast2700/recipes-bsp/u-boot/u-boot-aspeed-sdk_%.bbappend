require aspeed-coprocessor.inc
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

#Dual Image
SRC_URI:append:ast2700-default = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image', ' file://0001-Add-hw-failsafe-bootsupport-for-ast2700.patch', '', d)}"

SRC_URI:append:ast2700-default = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image', ' file://0001-Fixed-the-erase-method-boot-issue.patch', '', d)}"

DUAL_IMAGE_PATCHES = " file://0001-Fix-for-dual-image-hardware-failsafe-in-ast2700evb.patch \
		     "
SRC_URI:append:ast2700-default = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image', '${DUAL_IMAGE_PATCHES}', '', d)}"

SRC_URI:append = " \
	file://disable-kernel-fitimage-signature-verify-via-cptra.cfg \
	file://0001-Software-Secure-Boot-workaround.patch \
	file://0002-Update-the-OTP-info-for-AST2700-A2-in-SDKv11_02-migration.patch \
	file://0003-drivers-usb-aspeed-SDK-migration-to-v11.02.patch \
    "

SRC_URI:append = " \
	file://0001-clk-aspeed-ast2700-fix-clkgate-register-selection-fo.patch \
	file://0001-misc-sli_ast2700-Clear-status-at-SLIM-retry.patch \
	file://0001-edaf_bridge-clear-SAFS-size-setting-for-channel-3.patch \
	file://0001-drivers-reset-ast2700-fix-the-reset_status-typo.patch \
	file://0001-dts-arm-ast2700-Fix-bug-for-SPI2-Quad-IO-settings.patch \
	file://0001-cmd-aspeed-support-rgmii-interface-option.patch \
	file://0002-clk-aspeed-add-timeout-for-MAC-TX-polling.patch \
	file://0003-net-dwc_eth_xgmac-migrate-from-mainline-U-boot.patch \
	file://0004-net-dwc_eth_xgmac-guard-SoCFPGA-compatible-match.patch \
	file://0005-net-dwc_eth_xgmac-add-ASPEED-glue-layer.patch \
	file://0006-net-dwc_eth_xgmac-add-ASPEED-clock-and-reset-control.patch \
	file://0007-net-dwc_eth_xgmac-configure-AXI-bus-from-device-tree.patch \
	file://0008-phy-dw_xpcs-add-Synopsys-DesignWare-XPCS-driver.patch \
	file://0009-net-dwc_eth_xgmac-add-10G-support-and-update-ASPEED-.patch \
	file://0010-cmd-aspeed-add-support-for-AST27x5.patch \
	file://0011-cmd-aspeed-nettest-add-multicast-filter-test.patch \
	file://0012-cmd-aspeed-add-ext-parameter.patch \
	file://0013-cmd-aspeed-nettest-fix-AST2705-reset-handling.patch \
	"
# SDK migration to v11.03 - Generic patches
SRC_URI:append = " \
    file://0001-clk-aspeed-ast2700-add-AST2705-SOC1-clock-support_sdk_11.03.patch \
    file://0002-dts-arm-ast2705-add-EVB-device-tree_sdk_11.03.patch \
    file://0003-configs-evb-ast2705-add-AST2705-EVB-defconfig_sdk_11.03.patch \
    file://0004-dt-binding-reset-add-AST2755-XPCS-reset-define_sdk_11.03.patch \
    file://0005-dts-arm-ast2705-add-XGMAC-node_sdk_11.03.patch \
    file://0006-dts-arm-ast2705-evb-enable-XGMAC_sdk_11.03.patch \
    file://0007-arm-mach-aspeed-add-AST2705-SoC-support_sdk_11.03.patch \
    file://0008-pinctrl-aspeed-extend-AST2700-pinctrl-to-cover-AST27_sdk_11.03.patch \
    file://0009-dts-arm-ast2705-clean-up-XGMAC-properties_sdk_11.03.patch \
    file://0010--clk-aspeed-add-mac.o-for-AST2705_sdk_11.03.patch \
    file://0011-configs-evb-ast2705-switch-to-CONFIG_ASPEED_AST2705_sdk_11.03.patch \
    file://0012-board-aspeed-add-evb-ast2705-board-support_sdk_11.03.patch \
    file://0013-board-aspeed-add-ast2705-dcscm-board-support_sdk_11.03.patch \
    file://0014-arm-arch-aspeed-add-AST2705-platform-definitions_sdk_11.03.patch \
    file://0015-ram-aspeed-add-SDRAM-support-for-AST2705_sdk_11.03.patch \
    file://0016-dts-arm-move-ast2705-evb.dtb-under-CONFIG_ASPEED_AST_sdk_11.03.patch \
    file://0017-dts-arm-ast2705-simplify-XGMAC-DT-node_sdk_11.03.patch \
    file://0018-configs-evb-ast2705-run-bootmac-for-MAC-boot_sdk_11.03.patch \
    file://0019--arm-mach-aspeed-ast2705-detect-MAC-recovery-boot_sdk_11.03.patch \
    file://0020-configs-evb-ast2705-enable-ASPEED-XGMAC_sdk_11.03.patch \
    file://0021-arm-mach-aspeed-ast2705-add-recovery-strap-bits_sdk_11.03.patch \
    file://0022-board-aspeed-evb-ast2705-add-MAC-boot-command_sdk_11.03.patch \
    file://0023-clk-aspeed-ast2700-remove-RGMII-calibration-helper_sdk_11.03.patch \
    file://0024-arm-mach-aspeed-add-RGMII-calibration_sdk_11.03.patch \
    file://0025-arm-mach-aspeed-refine-RGMII-calibration-delay-handl_sdk_11.03.patch \
    file://0026-drivers-reset-ast2700-add-AST2705-support_sdk_11.03.patch \
    file://0027-reset-aspeed-extend-AST2700-reset-driver-to-cover-AS_sdk_11.03.patch \
"
# SDK migration to v11.03 - OTP driver patches
SRC_URI:append = " \
    file://0001-cmd-otp_info-update-otpstrap_ext-for-ast2700a2_sdk_11.03.patch \
    file://0002-cmd-aspeed-otp-add-user-region-support-for-prog-imag_sdk_11.03.patch \
    file://0003-cmd-aspeed-otp_info-update-ast2700a2-otp-info-table_sdk_11.03.patch \
    file://0004-cmd-aspeed-otp-add-OEM-binary-data-key-type-support-_sdk_11.03.patch \
	"
# SDK migration to v11.03 - SPI driver patches
SRC_URI:append = " \
    file://0001-mtd-spi-nor-Add-XMC-XM25QH01D-flash-part_sdk_11.03.patch \
	"
# SDK migration to v11.03 - LTPI driver patches
SRC_URI:append = " \
    file://0001-cmd-aspeed-ltpi-Fix-LVDS_TX_DS_EN-bit-and-drop-bogus_sdk_11.03.patch \
	"
# SDK migration to v11.03 - I2C driver patches
SRC_URI:append = " \
    file://0001-i2c-ast2600-introduce-buffer-mode-for-i2c_sdk_11.03.patch \
    file://0002-i2c-ast2600-add-delay-to-satisfy-tBUF-requirement_sdk_11.03.patch \
"
