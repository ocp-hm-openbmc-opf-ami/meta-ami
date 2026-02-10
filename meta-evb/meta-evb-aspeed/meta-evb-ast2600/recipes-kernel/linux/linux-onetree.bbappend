FILESEXTRAPATHS:prepend := "${THISDIR}/linux-onetree:"

SRC_URI += "file://dts-evb-ast2600/ \
	    file://enable_sgpio.cfg \
            file://ast2600evb.config \
            file://ipmb_dev.cfg \
            file://enable_jtag.cfg \
            file://enbale_pwm.cfg \
            file://0001-memoryleak-fix-after-deleted-files.patch \
            file://0001-Fix-IPMB-remote-device-not-get-response.patch \
            file://Enable_MCTP_PCIe.cfg \
            file://0002-I2C-bus-error-message-for-fault-alarm-support.patch \
            "

do_configure:append (){
    cp ${WORKDIR}/dts-evb-ast2600/aspeed-ast2600-evb.dts ${S}/arch/arm/boot/dts/aspeed/
    cp ${WORKDIR}/dts-evb-ast2600/openbmc-flash-layout-ami-evb-64.dtsi ${S}/arch/arm/boot/dts/aspeed/

    if ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image', 'true', 'false', d)}; then
        cp ${WORKDIR}/dts-evb-ast2600/aspeed-ast2600-evb-dual-image-support-dual-spi-abr.dts ${S}/arch/arm/boot/dts/aspeed/aspeed-ast2600-evb.dts
        cp ${WORKDIR}/dts-evb-ast2600/openbmc-flash-layout-ami-evb-64-alt.dtsi ${S}/arch/arm/boot/dts/aspeed/
    fi

    if ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-single-spi-abr', 'true', 'false', d)}; then
        cp ${WORKDIR}/dts-evb-ast2600/aspeed-ast2600-evb-dual-image-support-single-spi-abr.dts ${S}/arch/arm/boot/dts/aspeed/aspeed-ast2600-evb.dts
        cp ${WORKDIR}/dts-evb-ast2600/openbmc-flash-layout-ami-evb-128-singlespiabr.dtsi ${S}/arch/arm/boot/dts/aspeed/
    fi

    if ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-ncsi-support', 'true', 'false', d)}; then
        cp ${WORKDIR}/dts-evb-ast2600/aspeed-ast2600-evb-ncsi.dtsi ${S}/arch/arm/boot/dts/aspeed/
        echo '#include "aspeed-ast2600-evb-ncsi.dtsi"' >> ${S}/arch/arm/boot/dts/aspeed/aspeed-ast2600-evb.dts
    fi
}


