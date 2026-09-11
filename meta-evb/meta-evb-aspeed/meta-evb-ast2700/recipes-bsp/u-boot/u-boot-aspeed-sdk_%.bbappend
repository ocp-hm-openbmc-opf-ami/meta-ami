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
	"
