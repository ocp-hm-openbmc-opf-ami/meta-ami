PACKAGECONFIG:append = " verify_signature"
python __anonymous() {
    d.setVar('OPTIONAL_IMAGES', 'image-bios,image-cpld,image-pldm,image-raid,image-psu')
}
DEPENDS:remove = "libpldm"
RDEPENDS:${PN}-updater:remove = "libpldm"
FILES:${PN}-updater:remove = "${libexecdir}/phosphor-code-mgmt/pldm-bundle-extraction-tool"
FILES:${PN}-updater:remove = "${bindir}/fwupd-reboot-decision.sh"
FILES:${PN}-updater:prepend = " ${systemd_unitdir}/system/fwupd@.service "

do_install[postfuncs] += "nxp_cleanup_fwupd_reboot_decision"

nxp_cleanup_fwupd_reboot_decision() {
	rm -f ${D}${bindir}/fwupd-reboot-decision.sh
}

SRC_URI:remove = " \
	file://0001-AMI-Combined-all-firmware-update-patches.patch \
	file://0004-pldm-bundle-raw-upload-and-activation-improvements.patch \
	file://0005-pldm-package-parser-libpldm-api-compat.patch \
	file://0006-Added-Parallel-FW-update-support.patch \
	file://0014-Run-deferred-image-deletes-on-main-async-context.patch \
"
