FILESEXTRAPATHS:prepend := "${THISDIR}/linux-onetree:"

SRC_URI += "file://dts-evb-ast2700-dcscm/ \
           "

do_configure:append (){
    cp ${WORKDIR}/dts-evb-ast2700-dcscm/*.dts ${S}/arch/arm64/boot/dts/aspeed/
    cp ${WORKDIR}/dts-evb-ast2700-dcscm/*.dtsi ${S}/arch/arm64/boot/dts/aspeed/
}

