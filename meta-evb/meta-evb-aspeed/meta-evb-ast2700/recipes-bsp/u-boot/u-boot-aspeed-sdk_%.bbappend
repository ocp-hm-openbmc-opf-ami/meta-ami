#require aspeed-ssp-tsp.inc
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

#Dual Image
SRC_URI:append:ast2700-default = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image', ' file://0001-Add-hw-failsafe-bootsupport-for-ast2700.patch', '', d)}"

SRC_URI:append:ast2700-default = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image', ' file://0001-Fixed-the-erase-method-boot-issue.patch', '', d)}"

# SRC_URI:append:ast2700-a0-default = " \
#         file://uboot-fdtspiaddr.cfg  \
#         "
# SRC_URI:append:ast2700-dcscm = " \
#         file://uboot-fdtspiaddr.cfg  \
#         "

# SRC_URI:append = " file://0001-adding-Fieldmode-to-enable-failure-when-signature-va.patch "

SRC_URI:append = "  file://0001-ram-sdram_ast2700-Correct-vga-node-detect-rule.patch \
                        "
SRC_URI:append = " file://0001-arch-arm-ast2600-cpu-info-fix-bit-shifting-for-hash-.patch \
			file://0002-arm-ast2700-Update-WDT-reset-event-log-bit.patch \
			file://0003-arm-aspeed-Add-AST2700-A2-chip-ID.patch \
			file://0004-pinctrl-soc1-add-a-group-for-RMII-RCLK-OUT.patch \
			file://0005-configs-ibex-ast2700-Add-VGA-to-avoid-build-err.patch \
			file://0006-board-ibex_ast2700-Enable-MSI-and-INTA-on-bridge.patch \
			file://0009-misc-aspeed_edaf_bridge-refactor-variable-usage.patch \
			file://0010-misc-edaf_bridge-Update-compatible-strings-and-add-c.patch \
			file://0011-riscv-dts-Add-EDAF-bridge-global-cfg-node.patch \
			file://0012-misc-edaf_bridge-Add-eDAF-bridge-configuration-for-e.patch \
			file://0013-misc-edaf_bridge-Fix-typo.patch \
			file://0014-configs-ibex-ast2700-Update-bootloader-fit-load-addr.patch \
			file://0015-misc-sli_2700-Fix-SLIM-calibration-rarely-fail.patch \
			file://0016-configs-evb-ast2700-add-ECDSA-and-ECDSA_VERIFY-suppo.patch \
			file://0017-arch-arm-dts-ast2700-reserved-mem-add-ipc_bootmcu_sh.patch \
			file://0018-lib-aspeed-add-cptra_dice-library.patch \
			file://0019-lib-ecdsa-verify-add-stash-measurement-for-attestati.patch \
			file://0020-clk-aspeed-Record-delay-result-into-scratch-reg.patch \
			file://0021-board-ibex_ast2700-Enable-pcie-settings-for-all-27xx.patch \
			file://0022-configs-evb-ast2700-disable-FIT-signature-configure-.patch \
			file://0023-dts-ast2700-evb-update-memory-nodes-with-no-map-prop.patch \
			file://0024-dts-ast2700-ibex-update-reserved-memory-mappings.patch \
			file://0025-arm-riscv-aspeed-Add-reserved-memory-nodes-for-ATF-a.patch \
			file://0026-configs-evb-ast2700-enable-FIT-signature-configure.patch \
			file://0028-dts-ast2700-ibex-Rename-eDAF-DDR-mode-node-for-consi.patch \
			file://0029-aspeed-clock-Modify-clock-selection-lock.patch \
			file://0030-arch-arm-mach-aspeed-add-secure-boot-support.patch \
			file://0031-misc-sli_ast2700-Enhance-pad-delay-calibration-funct.patch \
			file://0032-riscv-aspeed-Enable-SSP-TSP-reset-bits-in-reset-mask.patch \
			file://0001-fixed-compilation-errors.patch \
			file://enable-aspeed-cptra.cfg \
			file://0001-Migration-SDK-v10.00-OTP-SWSecreBoot-to-OT.patch \
			file://0033-net-aspeed_mdio-add-cl45-support.patch \
			"

SRC_URI:append = " file://0001-ltpi-Lock-SGPIO-output-only-during-serial-output-sou.patch \
                       file://0002-drivers-ast2700-mailbox-add-waitting-tx-bit-clear-be.patch \
                       file://0003-dts-ast2700-add-timeout-setting-for-mailbox-2.patch \
                       file://0004-cmd-aspeed_mbox-add-ltpi-access-command.patch \
                       file://0005-arch-arm-dts-ast2700-evb-add-mailbox-bootmcu-device-.patch \
                       file://0006-drivers-ast2700-mailbox-add-wait-bit-clear-in-the-mb.patch \
                       file://0007-drivers-aspeed_mbox-add-invalid-d-cache-in-the-mbox-.patch \
                       file://0008-ltpi-add-fine-grained-control-for-pinctrl-settings.patch \
                       file://0009-dts-ast2700-add-mail-box-to-bootmcu-setting.patch \
                       file://0010-cmd-aspeedmbox-add-ltpi-channel-info-into-misc.patch \
                       "

SRC_URI:append = " file://0001-spi-aspeed-Porting-set_speed-callback-function.patch "
SRC_URI:append = " file://0002-sdk-upgrade-9.08_aspeed_vga.patch "
SRC_URI:append = " file://0001-Network-Driver-Aspeed-SDK-908-Migration.patch "

SRC_URI:append = " file://0001-mtd-spi-nor-Check-nor-info-before-setting-macronix_o.patch \
		   file://0001-spi-aspeed-Use-lower-frequency-to-probe-SPI-flash.patch \
		 "
SRC_URI:append = " file://0001-eDAF-enable-edaf_bridge-node-in-uboot-stage.patch \
		   file://0001-configs-use-SPL_-prefix-for-SPL-compatibility.patch \
		   file://0001-configs-ibex-ast2700-enable-ASPEED_OTP-support.patch \
		   file://0001-misc-aspeed_vga-Add-function-to-get-gfx-mem-control.patch \
		   file://0001-board-ibex_ast2700-Enable-pcie-settings-for-all-27xx.patch \
		   file://0001-pinctrl-aspeed-ast2700_soc1-Fix-register-offset-addr.patch \
		   file://0001-gpio-aspeed-add-pinctrl-based-GPIO-request-support.patch \
		   file://0001-dts-ast2700-evb-Refine-reserved-memory.patch \
		   file://0001-dts-ast2700-ibex-reserved-mem-Refine-reserved-memory.patch \
		   file://0001-dts-ast2700-evb-reserved-mem-mmbi-align-to-64MB.patch \
		   file://0001-dts-ast2700-ibex-reserved-mem-mmbi-align-to-64MB.patch \
		 "
