FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

OVERRIDES .= ":uboot-flash-${FLASH_SIZE}"

# We don't have 'u-boot-initial-env' target in our u-boot version
UBOOT_INITIAL_ENV = ""

PV = "v2019.04+git${SRCPV}"

UBOOT_MAKE_TARGET ?= "DEVICE_TREE=${UBOOT_DEVICETREE}"

require recipes-bsp/u-boot/u-boot.inc

PROVIDES += "u-boot"
DEPENDS += "bc-native dtc-native"

SRC_URI:append:df-phosphor-mmc = " file://u-boot-env-ast2600.txt"
SRC_URI += " \
            file://rsa_oem_dss_key.pem;sha256sum=64a379979200d39949d3e5b0038e3fdd5548600b2f7077a17e35422336075ad4 \
            file://rsa_pub_oem_dss_key.pem;sha256sum=40132a694a10af2d1b094b1cb5adab4d6b4db2a35e02d848b2b6a85e60738264 \
            file://user/ \
           "

SOCSEC_SIGN_KEY ?= "${UNPACKDIR}/rsa_oem_dss_key.pem"
SOCSEC_SIGN_ALGO ?= "RSA4096_SHA512"
SOCSEC_SIGN_EXTRA_OPTS ?= "--stack_intersects_verification_region=false --rsa_key_order=big"

OTPTOOL_USER_DIR ?= "${UNPACKDIR}/user"

inherit socsec-sign
inherit otptool

UBOOT_ENV_SIZE:df-phosphor-mmc = "0x10000"
UBOOT_ENV:df-phosphor-mmc = "u-boot-env"
UBOOT_ENV_SUFFIX:df-phosphor-mmc = "bin"
UBOOT_ENV_TXT:df-phosphor-mmc = "u-boot-env-ast2600.txt"

SRC_URI:append = " \
    file://dts-common/ \
    file://ast2600_a3.json \
    file://Fix-for-tftp-flashing-conflicts.patch \
    file://0005-Fix-NCSI-in-UBoot.patch \
    file://0012-Fix_to_resolve_compilation_issue.patch \
    "

SRC_URI += " \
        file://CVE-2024-57256.patch \
        file://CVE-2024-57258.patch \
        file://CVE-2019-11690.patch \
        "

SRC_URI:append:evb-ast2600 = "file://0007-Save-env-variables-before-autoboot.patch "

SRC_URI:append:oks-features = " file://0008-update-address-of-fdt-location.patch "

EVB_SRC_URI = " file://spl.cfg"
AC_SRC_URI = " file://spl_archercity.cfg"
NO_SPL_URI = " file://nospl.cfg"

SRC_URI:append:evb-ast2600 = "${@bb.utils.contains('SPL_BINARY', 'spl/u-boot-spl.bin', EVB_SRC_URI, '', d)}"
SRC_URI:append:intel-ast2600 = "${@bb.utils.contains('SPL_BINARY', 'spl/u-boot-spl.bin', AC_SRC_URI, NO_SPL_URI, d)}"

#Enable ASPEED SOC Secure Boot
SOCSEC_SIGN_ENABLE = "0"

SOCSEC_SIGN_KEY = "${WORKDIR}/keys/SIG_RSA_KEY2_private.pem"
SOCSEC_SIGN_ALGO = "RSA2048_SHA256"
OTPTOOL_CONFIGS = "${WORKDIR}/ast2600_a3.json"
OTPTOOL_KEY_DIR = "${WORKDIR}/keys/"

SOCSEC_SIGN_EXTRA_OPTS = "--rsa_key_order=little"

do_deploy:prepend() {
        # otptool needs access to the public and private socsec signing keys in the keys/ directory. uncomment if SOCSEC enabled
        # openssl rsa -in ${SOCSEC_SIGN_KEY} -pubout > ${S}/keys/SIG_RSA_KEY2_public.pem
}

SRC_URI_NON_PFR = "file://0001-adding-Fieldmode-to-enable-failure-when-signature-va.patch \
                    "
SRC_URI_NON_PFR:append:emmc-sw-ami = "file://0006-emmc-support-bootarg.patch"

SRC_URI_NON_PFR_DUAL:append = " file://0002-adding-support-for-non-pfr-dual-image-feature.patch \
                                "
SRC_URI:append:intel-ast2600 = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image', SRC_URI_NON_PFR_DUAL,'', d)}"

SRC_URI_NON_PFR_HW_FAILSAFE_BOOT:append = ""

SRC_URI_NON_PFR_HW_FAILSAFE_BOOT:append:intel-ast2600 = " file://0003-add-hw-failsafe-boot-support.patch \
                                            "

SRC_URI_NON_PFR_HW_FAILSAFE_BOOT:append:evb-ast2600 = " file://0004-add-hw-failsafe-boot-support-for-evb.patch \
                                            "

SRC_URI:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-hw-failsafe-boot', SRC_URI_NON_PFR_HW_FAILSAFE_BOOT,'', d)}"
SRC_URI:append = " ${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '', SRC_URI_NON_PFR, d)}"

SRC_URI:append:intel-ast2600 = "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '', ' file://flash-layout-update.cfg  ', d)}"

SRC_URI:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'allow-root-login', '', 'file://boot_delay.cfg', d)}"

SRC_URI:append = " file://0001-board-ast2600-Remove-eSPI-PC-and-VW-initialization-c.patch "
SRC_URI:append = " file://0001-Updated-U-Boot-Patches-for-DP-and-VGA-Support.patch "
SRC_URI:append = " file://0001-Add-aspeed-AST2600-DP-CTS-command-utility.patch "
SRC_URI:append = " file://0009-net-ftgmac100-get-tx-rx-internal-delay-ps.patch \
                   file://0011-net-ftgmac100-Add-RGMII-delay-support-for-AST2600.patch \
                  "

# MAC FROM EEPROM SUPPORT

MAC_EEPROM_COMMON = ""

MAC_EEPROM_COMMON:append = " file://0001-mac_eeprom_support.patch "

MAC_EEPROM_COMMON:append:intel-ast2600 = " file://mac_eeprom_support_intel_bhs.cfg \
                                                     "
MAC_EEPROM_COMMON:append:evb-ast2600 = " file://mac_eeprom_support_evb_2600.cfg \
                                                   "

SRC_URI:append = "${@bb.utils.contains('EXTRA_IMAGE_FEATURES', 'onetree-mac-eeprom-support', MAC_EEPROM_COMMON,'', d)}"

do_configure:append (){
        cp ${UNPACKDIR}/dts-common/ast2600-dp-fw.dtsi ${S}/arch/arm/dts/
        cp ${UNPACKDIR}/dts-common/ast2600-evb-tee.dts ${S}/arch/arm/dts/
}

do_compile:append() {
    if [ -n "${UBOOT_ENV}" ]
    then
        # Generate redundant environment image
        ${B}/tools/mkenvimage -r -s ${UBOOT_ENV_SIZE} -o ${B}/${UBOOT_ENV_BINARY} ${UNPACKDIR}/${UBOOT_ENV_TXT}
    fi
}
