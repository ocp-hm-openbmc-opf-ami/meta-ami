FILESEXTRAPATHS:prepend:= "${THISDIR}/files:"

SRC_URI:append = " \
	file://0001-Adding_new_file_i2c-npcm_u-boot.patch \
	file://0002-Add-Uboot-Default-PWM-Setting.patch \
	file://0003-Enable-auto-negotiation-of-SGMII-mode-at-U-boot.patch \
	file://0004-read-mac-and-chksum-from-eeprom-wo-dts.patch.patch \
	file://0005-Re-enable-sgmii-auto-neg-feature-after-set-PCS-mode.patch \
	file://0006-u-boot-arbel-Add-the-WOL-init-sequence-as-part-of-la.patch \
	file://0007-Modified-i2c-eeprom-file.patch \
	file://enable-i2c-eeprom.cfg \
	file://disable_wdt_autostart.cfg \
	file://0008-enable-fieldmode-in-uboot-and-save-the-env-before-au.patch \
	"
