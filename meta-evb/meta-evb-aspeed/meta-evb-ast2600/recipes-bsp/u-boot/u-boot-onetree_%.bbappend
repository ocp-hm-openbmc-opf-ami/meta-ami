FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

COMPATIBLE_MACHINE = "evb-ast2600"

SRC_URI:append:emmc-sw-ami = " \
	file://emmc-support.cfg  \
	"

NCSI_SRC_URI = "file://ncsi.cfg \
               "

SRC_URI:append:evb-ast2600 = " \
    file://dts-2600evb \
    file://fw_env_evb.config \
    file://0001-Resolved-boot-spi-error.patch \
    file://evb_ast2600.cfg \
    "
do_install:prepend:evb-ast2600 () {
    cp ${UNPACKDIR}/fw_env_evb.config ${S}/fw_env.config
    install -m 0644 ${UNPACKDIR}/fw_env_evb.config ${S}/tools/env/fw_env.config
}

do_install:append:evb-ast2600 () {
    install -m 0644 ${UNPACKDIR}/fw_env_evb.config ${D}${sysconfdir}/fw_env.config
}

SRC_URI:append = " ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-ncsi-support', NCSI_SRC_URI, '', d)}"

do_configure:append:evb-ast2600 (){

    # Copy dts/dtsi files
    cp ${UNPACKDIR}/dts-2600evb/*.dtsi ${S}/arch/arm/dts/
    cp ${UNPACKDIR}/dts-2600evb/*.dts ${S}/arch/arm/dts/

    if ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-ncsi-support', 'true', 'false', d)}; then
	cp ${UNPACKDIR}/dts-2600evb/ast2600-evb-ncsi.dtsi ${S}/arch/arm/dts/
	echo '#include "ast2600-evb-ncsi.dtsi"' >> ${S}/arch/arm/dts/ast2600-evb.dts
    fi

    if ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-mac-eeprom-support', 'true', 'false', d)}; then
	cp ${UNPACKDIR}/dts-2600evb/ast2600-evb-mac-eeprom.dtsi ${S}/arch/arm/dts/
	echo '#include "ast2600-evb-mac-eeprom.dtsi"' >> ${S}/arch/arm/dts/ast2600-evb.dts
    fi

}
