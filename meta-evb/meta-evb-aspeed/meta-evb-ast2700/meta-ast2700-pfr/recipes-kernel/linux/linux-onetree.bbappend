FILESEXTRAPATHS:prepend := "${THISDIR}/linux-onetree:"

SRC_URI += "file://dts-evb-ast2700-dcscm/ \
            file://dts-evb-ast2700-a0-dcscm/ \
           "

do_configure:append:ast2700-dcscm (){
    cp ${WORKDIR}/dts-evb-ast2700-dcscm/*.dts ${S}/arch/arm64/boot/dts/aspeed/
    cp ${WORKDIR}/dts-evb-ast2700-dcscm/*.dtsi ${S}/arch/arm64/boot/dts/aspeed/
}

do_configure:append:ast2700-a0-dcscm (){
    cp ${WORKDIR}/dts-evb-ast2700-a0-dcscm/*.dts ${S}/arch/arm64/boot/dts/aspeed/
    cp ${WORKDIR}/dts-evb-ast2700-a0-dcscm/*.dtsi ${S}/arch/arm64/boot/dts/aspeed/
}

