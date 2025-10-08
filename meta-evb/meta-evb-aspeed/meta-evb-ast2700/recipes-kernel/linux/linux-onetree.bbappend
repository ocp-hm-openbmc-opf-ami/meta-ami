FILESEXTRAPATHS:prepend := "${THISDIR}/linux-onetree:"

DEPENDS += "lzop-native"
DEPENDS += "${@bb.utils.contains('MACHINE_FEATURES', 'ast-secure', 'aspeed-secure-config-native', '', d)}"

SRC_URI:append = " file://ipmi_ssif.cfg "
SRC_URI:append = " file://mtd_test.cfg "
SRC_URI:append = " file://crpyto_manager.cfg "
SRC_URI:append:spi-nor-ecc = " file://jffs2_writebuffer.cfg "
SRC_URI:append = " file://iptables.cfg "

SRC_URI:append = "  file://nfs_cifs.cfg "

SRC_URI:append = "  file://aspeed_g7_defconfig "
SRC_URI:append = " file://iproute2.cfg "
SRC_URI:append = " file://iproute.cfg "
SRC_URI:append = " file://bond.cfg "
SRC_URI:append = " file://0002-Add-PowerSaveMode-Support-for-AST2700-PortA.patch "
SRC_URI:append:ast2700-a0-default = " file://0004-Revert-SGPIO-slave-to-control-parallel-data-for-A0.patch "
SRC_URI:append:ast2700-a0-dcscm = " file://0004-Revert-SGPIO-slave-to-control-parallel-data-for-A0.patch "

SRC_URI:append = " file://0001-AST2700EVB-Fix-for-compilation-error.patch "

SRC_URI += "file://dts-evb-ast2700-default/ \
            file://dts-evb-ast2700-a0-default/ \
            "

do_configure:append:ast2700-default (){
    cp ${WORKDIR}/dts-evb-ast2700-default/*.dts ${S}/arch/arm64/boot/dts/aspeed/
    cp ${WORKDIR}/dts-evb-ast2700-default/*.dtsi ${S}/arch/arm64/boot/dts/aspeed/
}

do_configure:append:ast2700-a0-default (){
    cp ${WORKDIR}/dts-evb-ast2700-a0-default/*.dts ${S}/arch/arm64/boot/dts/aspeed/
    cp ${WORKDIR}/dts-evb-ast2700-a0-default/*.dtsi ${S}/arch/arm64/boot/dts/aspeed/
}

do_kernel_metadata:prepend() {
    install -d ${S}/arch/arm64/configs
    cp ${WORKDIR}/aspeed_g7_defconfig ${S}/arch/arm64/configs/
}
