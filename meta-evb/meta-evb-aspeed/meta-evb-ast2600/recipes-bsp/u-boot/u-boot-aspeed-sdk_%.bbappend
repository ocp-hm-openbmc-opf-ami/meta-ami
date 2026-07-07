FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

COMPATIBLE_MACHINE = "evb-ast2600"

SRC_URI:append:emmc-sw-ami = " \
	file://emmc-support.cfg  \
	"

NCSI_SRC_URI = "file://ncsi.cfg \
                file://0001-Update-DTS-File-for-Uboot-Enable-NCSI-on-MAC3-and-Disable-MAC2.patch \
               "

SRC_URI:append:evb-ast2600 = " \
    file://fw_env_evb.config \
    file://0001-Resolved-boot-spi-error.patch \
    file://evb_ast2600.cfg \
    file://BMC_HOST.patch \
    "
do_install:prepend:evb-ast2600 () {
	cp ${UNPACKDIR}/fw_env_evb.config ${S}/fw_env.config
	install -m 0644 ${UNPACKDIR}/fw_env_evb.config ${S}/tools/env/fw_env.config
}

do_install:append:evb-ast2600 () {
	install -m 0644 ${UNPACKDIR}/fw_env_evb.config ${D}${sysconfdir}/fw_env.config
}

SRC_URI:append = " file://0004-ARM-dts-ast2600-evb-Configure-RGMII-delay-for-MAC.patch "

SRC_URI:append = " ${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-network-ncsi-support', NCSI_SRC_URI, '', d)}"


