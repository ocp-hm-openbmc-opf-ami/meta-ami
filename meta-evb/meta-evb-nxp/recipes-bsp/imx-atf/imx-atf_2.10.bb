# Copyright 2017-2026 NXP

DESCRIPTION = "i.MX ARM Trusted Firmware"
SECTION = "BSP"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/BSD-3-Clause;md5=550794465ba0ec5312d6919e203a55f9"

PV .= "+git${SRCPV}"

ATF_SRC ?= "git://github.com/nxp-imx/imx-atf.git;protocol=https"
SRC_URI = "${ATF_SRC};branch=${SRCBRANCH}"
SRCBRANCH = "lf_v2.10"
SRCREV = "28affcae957cb8194917b5246276630f9e6343e1"

S = "${WORKDIR}/git"

inherit deploy

ATF_BOOT_UART_BASE ?= ""

EXTRA_OEMAKE += " \
    CROSS_COMPILE=aarch64-none-elf- \
    PLAT=${ATF_PLATFORM} \
    IMX_BOOT_UART_BASE=${ATF_BOOT_UART_BASE} \
    DEBUG=${ATF_DEBUG} \
"

# Unexport problematic flags
CFLAGS[unexport] = "1"
LDFLAGS[unexport] = "1"
AS[unexport] = "1"
LD[unexport] = "1"

INHIBIT_DEFAULT_DEPS = "1"
DEPENDS = "gcc-aarch64-none-elf-native"

BUILD_OPTEE = "${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'true', 'false', d)}"

ATF_DEBUG ?= "0"
EXTRA_OEMAKE += 'DEBUG=${ATF_DEBUG}'
OUTPUT_FOLDER = "${@bb.utils.contains('ATF_DEBUG', '0', 'release', 'debug', d)}"

do_configure[noexec] = "1"

do_compile() {
    oe_runmake bl31
    if ${BUILD_OPTEE}; then
        oe_runmake clean BUILD_BASE=build-optee
        oe_runmake BUILD_BASE=build-optee SPD=opteed bl31
    fi
}

do_install[noexec] = "1"

BOOT_TOOLS = "imx-boot-tools"

addtask deploy after do_compile
do_deploy() {
    install -Dm 0644 ${S}/build/${ATF_PLATFORM}/${OUTPUT_FOLDER}/bl31.bin ${DEPLOYDIR}/bl31-${ATF_PLATFORM}.bin
    install -Dm 0644 ${S}/build/${ATF_PLATFORM}/${OUTPUT_FOLDER}/bl31.bin ${DEPLOYDIR}/${BOOT_TOOLS}/bl31-${ATF_PLATFORM}.bin
    if ${BUILD_OPTEE}; then
        install -m 0644 ${S}/build-optee/${ATF_PLATFORM}/${OUTPUT_FOLDER}/bl31.bin ${DEPLOYDIR}/bl31-${ATF_PLATFORM}.bin-optee
        install -m 0644 ${S}/build-optee/${ATF_PLATFORM}/${OUTPUT_FOLDER}/bl31.bin ${DEPLOYDIR}/${BOOT_TOOLS}/bl31-${ATF_PLATFORM}.bin-optee
    fi
}

PACKAGE_ARCH = "${MACHINE_ARCH}"
COMPATIBLE_MACHINE = "(evb-imx93|evb-imx943|evb-imx95|mx9-generic-bsp)"
