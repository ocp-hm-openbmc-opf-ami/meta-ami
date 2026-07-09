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
    "
