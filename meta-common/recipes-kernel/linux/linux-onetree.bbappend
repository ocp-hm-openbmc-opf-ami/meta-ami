FILESEXTRAPATHS:prepend := "${THISDIR}/linux-onetree:"

SRC_URI:append:intel-ast2600 = " file://0001-Enabled-the-RTC-driver.patch \
				 file://0002-Intel-aspeed-g6-dtsi-changes.patch \
				 file://0003-Ported-PECI-driver-support-from-INTEL-AMI.patch \
				 file://0004-Work-Around-Fix-For-Peci-Time-Out.patch \
				 file://0005-adding-intel-hwmon-driver.patch \
				 file://0006-adding-intel-espi-and-lpc-sio-driver.patch \
				 file://0007-MakeFile-and-Kconfig-for-espi-and-lpc-sio.patch \
				 file://0008-fix-for-espi-and-peci-build-error.patch \
				 file://0009-adding-aspeed-espi-vw.patch \
				 file://0010-Fix-peci-for-ASPEED-MCTP-over-PCIe-driver.patch \
				 file://0011-fix-peci-driver-build-error.patch \
				 file://0012-makefile-and-kconfig-changes-for-peci-client.patch \
				 file://0013-update-aspeed-espi-mmbi-to-latest-intel-bkc.patch \
				 file://0014-fix-for-peci-coverity.patch \
				 file://0015-i3c_hub_support.patch \
				 file://0016-fix-for-host-misc-comm-manager-failed-to-load-aspeed.patch \
				 file://0017-add-lpc-sio-header.patch \
				 file://0018-fix-for-lpc-sio-not-loading.patch \
				 file://0019-add-aspeed-bmc-misc.patch \
				 file://0020-Enabled-mctp-i3c-socket-based-driver.patch \
				 file://0021-EID-to-lladdr-mappings-implemented.patch \
				 file://intel-i3c-hub.cfg \
				 file://intel-base.cfg \
			       "

SRC_URI += "file://defconfig \
"
SRC_URI += "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'debug-tweaks', 'file://debug.cfg ', '', d)}"

SRC_URI:append:intel-ast2600 = " ${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '',  " file://zram.cfg ", d)}"
