FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://nfs.cfg \
            file://usb-eth.cfg \
            file://0001-USB-Ethernet-Gadget-Host-Interface.patch \
            file://0002-Fixed-compilation-error-on-USB-gadget.patch \
            file://0011-Enable-Threshold-Attributes-for-Core-temperature-sen.patch \
            file://0001-Fix-virtual-USB-hub-not-working-for-evb-ast2600.patch \
	    file://0003-Fix-incorrect-MAC-address-in-RNDIS-driver.patch \
            file://0016-legacy-driver-support-for-pwm-driver.patch \
            file://0002-i3c-mctp-workaround-for-wrong-DCR-value.patch \
            file://0017-Add-write-public-key-in-image-support.patch \
            file://0018-Nm-sensor-Threshold-Support.patch \
            file://0018-USB-Support-Power-Save-Mode.patch \
            file://CVE-2023-31085.patch \
            file://iptables.cfg \
            file://CVE-2023-6531.patch \
            file://CVE-2023-6606.patch \
            file://CVE-2023-6817.patch \
  	    file://0029-ip_address_update_ncsi_interface.patch \
            file://0030-Fix-USB-gadget-hid-driver-for-kernel-upgrade.patch \
            file://0030-Add-SSIF-support.patch \
	    file://CVE-2023-6622.patch \
	    file://CVE-2024-0841.patch \
            file://CVE-2024-1085.patch \
            file://CVE-2024-1086.patch \
            file://0032-Fix-NCSI-Auto-Failover.patch \
	    "

NON_PFR_SRC_URI_AMI = "file://0012-Add-new-layout-as-per-AMI-requirements.patch \
                       file://0019-Fix-for-JFFS2-issue-due-to-SPI-tx-bus-width.patch \
                      "

SRC_URI:append:intel-ast2600 = "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '',NON_PFR_SRC_URI_AMI, d)}"

PFR_SRC_URI_AMI = "file://0027-pfr-fix-bhs-jffs2-issue-due-to-spi-tx-bus-width.patch \
                   file://0029-pfr-fix-egs-jffs2-issue-due-to-spi-tx-bus-width.patch \
                   file://0030-pfr256-add-winbond-w25q02jv-support.patch \
                  "

SRC_URI:append:intel-ast2600 = "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', PFR_SRC_URI_AMI, '', d)}"


SRC_URI_NON_PFR_DUAL:append:intel-ast2600 = "file://0013-Added-dts-configuration-for-dual-image-support.patch "
SRC_URI_NON_PFR_DUAL:append = "file://0024-add-fmc-ce0-ce1-acccess-support.patch "
SRC_URI_NON_PFR_DUAL:append:evb-ast2600  = "file://0025-add-dual-image-dts-support-for-evb.patch \
                                            file://0028-fix-dual-image-dts-for-evb.patch \
                                            "
SRC_URI:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'dual-image', SRC_URI_NON_PFR_DUAL,'', d)}"

SRC_URI_NON_PFR_SINGLE_SPI_ABR:append = "file://0026-add-hw-failsafe-boot-single-spi-abr-support.patch \
                                        "

SRC_URI:append:intel-ast2600 = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'single-spi-abr', SRC_URI_NON_PFR_SINGLE_SPI_ABR,'', d)}"

SRC_URI_NON_PFR_SINGLE_SPI_ABR_EVB:append = "file://0027-add-hw-failsafe-boot-single-spi-abr-support-for-evb.patch \
                                            "

SRC_URI:append:evb-ast2600 = " ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'single-spi-abr', SRC_URI_NON_PFR_SINGLE_SPI_ABR_EVB,'', d)}"


NETWORK_BONDING_SRC_URI += "file://bond.cfg \
                            file://0017-Disable-Default-Network-Bonding.patch \
                           "
SRC_URI += "${@bb.utils.contains('ENABLE_BONDING', 'network-bond', NETWORK_BONDING_SRC_URI,'', d)}"

SRC_URI_NM += "file://disable_nm_sensor.cfg \
               file://disable_smart.cfg \
               "
SRC_URI:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'nm-features', '', SRC_URI_NM, d)}"

SRC_BIOS = "file://0020-bios-patch-to-enable-pnor-mtd.patch "

SRC_URI:append:intel-ast2600  = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'bios-update', SRC_BIOS,'', d)}"

SRC_CPLD_SPI = "file://cpld-spidev.cfg \
file://0021-Enable-spidev-for-spi2-for-cpld-upgrade-via-spi.patch \
"
SRC_URI:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'cpld-update', SRC_CPLD_SPI,'', d)}"

SRC_CPLD = " file://0019-Enabling-JTAG0-for-CPLD-update-using-jatg.patch \
file://0022-Enable-spidev-for-spi2-for-cpld-upgrade-via-spi-intel-dts.patch \
"
SRC_URI:append:intel-ast2600  = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'cpld-update', SRC_CPLD,'', d)}"

SRC_CPLD_EVB = "file://0023-Enable-spidev-for-spi2-for-cpld-upgrade-via-spi-evb-dts.patch "
SRC_URI:append:evb-ast2600  = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'cpld-update', SRC_CPLD_EVB,'', d)}"

