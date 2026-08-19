FILESEXTRAPATHS:prepend := "${THISDIR}/linux-onetree:"

SRC_URI:append = " file://evb-npcm845.cfg"
SRC_URI:append = " file://enable-v4l2.cfg"
SRC_URI:append = " file://luks.cfg"

# for i3c slave test
SRC_URI:append = " file://i3c_mctp.cfg"

# for af_mctp test
SRC_URI:append = " file://mctp.cfg"

SRC_URI:append = " file://nfs_cifs.cfg \
                 "

SRC_URI += "file://dts-arbel-npcm845/ \
            file://i3c-arbel-npcm845/ \
            file://0004-Enable-usb-device-8-9-on-usbphy-2-3.patch \
            file://Enable_msft.cfg \
            file://0002-Add-workaround-for-using-header-file-in-user-space-w.patch \
            file://0001-rtl8211f-customized-led.patch \
            file://0003-Add-driver-for-HDC302x.patch \
            file://0004-Implement-hs401x-driver.patch \
            file://0005-Modify-driver-pmbus-Add-conpatible-table.patch \
            file://0006-Modify-driver-hwmon-pmbus-isl68137-Add-sensor-suppor.patch \
            file://0007-Support-current-reading-value-in-tps544c26-driver.patch \
            file://0008-Add-XDPE152x-temprature-config.patch \
            file://0009-Add-ADCSensor-support-and-retry-time-and-Continuous-mode-for-adc128d818.patch \
            file://0010-add-support-for-mbox-interface-for-mctp-endpoint-com.patch \
            file://0011-Add-pmbus-driver-support-for-mp5940.patch \
            file://0012-Add-skip-soft-reset-config-to-spi-nor-driver.patch \
            file://0013-Modify-driver-adm1275-Add-adm1281-and-adm1273-suppor.patch \
            file://0014-Support-ADC-ads112c04-driver.patch \
            file://0015-Add-pmbus-driver-support-for-tps53689t-and-tps536c9t.patch \
            file://0016-Add-a-clear-fault-flag-and-implement-support-to-exec.patch \
            file://0017-Add-pmbus-driver-support-for-delta-q54sn120a1.patch \
            file://0018-Add-the-function-to-set-the-number-of-ADC-samples-pe.patch \
            file://0019-enable-fiu1-spidev.patch \
            file://0020-Add-to-hwmon-for-support-TPS25990A-and-TPS546D24A-to.patch \
            file://0021-Add-bmr350-bmr351-to-pmbus.patch \
            file://0022-Support-PSU-hwmon-pmbus-driver-raa228926-to-isl68137.patch \
            file://0023-Add-pmbus-driver-for-Delta-Power-Brick.patch \
            file://0024-Add-max34452-driver-info.patch \
            file://0025-iio-adc-max1363-Add-ability-to-set-scale-of-the-ADC.patch \
            file://0026-iio-adc-ti-ads7142-Add-new-driver-support-for-ADS714.patch \
            file://0005-net-ethernet-stmmac-add-sgmii-support.patch \
            file://0028-hw-i2c-nuvoton-expose-bus-timeout-as-device-tree-pro.patch \
            file://0029-hw-i2c-nuvoton-log-bus-timeout-and-retries.patch \
            file://0030-Add-i2c-gpio-expander-driver-for-MSFT-FPGA.patch \
            "
SRC_URI:remove = "file://Enable_I3C.cfg"

SRC_URI:append = " file://0001-Nuvoton-drivers.patch \
		   file://0002-Nuvoton-include.patch \
		   file://0003-Nuvoton-net.patch \
		   file://0004-Nuvoton-Generic.patch \
		 "
do_configure:append (){

    cp ${UNPACKDIR}/dts-arbel-npcm845/nuvoton-npcm845-evb.dts ${S}/arch/arm64/boot/dts/nuvoton/
    cp -rf ${UNPACKDIR}/i3c-arbel-npcm845/drivers/i3c/* ${S}/drivers/i3c/
    cp -rf ${UNPACKDIR}/i3c-arbel-npcm845/include/linux/i3c/* ${S}/include/linux/i3c/
}

