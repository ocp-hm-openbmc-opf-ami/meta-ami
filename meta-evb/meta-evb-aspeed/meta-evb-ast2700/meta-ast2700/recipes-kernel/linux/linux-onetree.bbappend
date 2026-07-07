FILESEXTRAPATHS:prepend := "${THISDIR}/linux-onetree:"

SRC_URI += "file://dts-evb-ast2700-default/ \
	   "
do_configure:append (){

    cp ${UNPACKDIR}/dts-evb-ast2700-default/*.dts ${S}/arch/arm64/boot/dts/aspeed/
    cp ${UNPACKDIR}/dts-evb-ast2700-default/*.dtsi ${S}/arch/arm64/boot/dts/aspeed/
 
    if ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image', 'true', 'false', d)}; then
        cp ${UNPACKDIR}/dts-evb-ast2700-default/Dual_Image-ast2700-evb.dts ${S}/arch/arm64/boot/dts/aspeed/ast2700-evb.dts
        cp ${UNPACKDIR}/dts-evb-ast2700-default/aspeed-evb-flash-layout-128-dual-spi-alt.dtsi ${S}/arch/arm64/boot/dts/aspeed/
    fi

    if ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-single-spi-abr', 'true', 'false', d)}; then
        cp ${UNPACKDIR}/dts-evb-ast2700-default/Dual_image_single-spi-ast2700-evb.dts ${S}/arch/arm64/boot/dts/aspeed/ast2700-evb.dts
        cp ${UNPACKDIR}/dts-evb-ast2700-default/aspeed-evb-flash-layout-single-spi-abr.dtsi ${S}/arch/arm64/boot/dts/aspeed/
    fi

    #FIXME: ast2700a1-evb.dtsi contains A1 quirks not present in A2; remove when A1 is no longer supported.
    if ${@bb.utils.contains_any('MACHINE', 'ast2700-a1 ast2700-a1-spl', 'true', 'false', d)}; then
        echo '#include "ast2700a1-evb.dtsi"' >> ${S}/arch/arm64/boot/dts/aspeed/ast2700-evb.dts
    fi

}
