FILESEXTRAPATHS:prepend := "${THISDIR}/linux-onetree:"

SRC_URI += "file://dts-evb-ast2700-default/ \
	   "
do_configure:append (){

    cp ${WORKDIR}/dts-evb-ast2700-default/*.dts ${S}/arch/arm64/boot/dts/aspeed/
    cp ${WORKDIR}/dts-evb-ast2700-default/*.dtsi ${S}/arch/arm64/boot/dts/aspeed/
 
    if ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image', 'true', 'false', d)}; then
        cp ${WORKDIR}/dts-evb-ast2700-default/Dual_Image-ast2700-evb.dts ${S}/arch/arm64/boot/dts/aspeed/ast2700-evb.dts
        cp ${WORKDIR}/dts-evb-ast2700-default/aspeed-evb-flash-layout-128-dual-spi-alt.dtsi ${S}/arch/arm64/boot/dts/aspeed/
    fi

    if ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-single-spi-abr', 'true', 'false', d)}; then
        cp ${WORKDIR}/dts-evb-ast2700-default/Dual_image_single-spi-ast2700-evb.dts ${S}/arch/arm64/boot/dts/aspeed/ast2700-evb.dts
        cp ${WORKDIR}/dts-evb-ast2700-default/aspeed-evb-flash-layout-single-spi-abr.dtsi ${S}/arch/arm64/boot/dts/aspeed/
    fi
    

}
