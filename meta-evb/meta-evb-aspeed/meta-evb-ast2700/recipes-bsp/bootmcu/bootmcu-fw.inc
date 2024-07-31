SUMMARY = "BootMCU firmware and execute SPL"
DESCRIPTION = "BootMCU is designated to load the first, verified image for the main processor"
PACKAGE_ARCH = "${MACHINE_ARCH}"

DEPENDS = "ast2700-riscv-linux-gnu-native kern-tools-native swig-native ${PYTHON_PN}-setuptools-native"

do_install[noexec] = "1"

inherit deploy cml1 python3native

RISCV_PREBUILT_TOOLCHAIN = "${STAGING_DIR_NATIVE}${datadir}/ast2700-riscv-linux-gnu/bin/riscv32-unknown-linux-gnu-"

EXTRA_OEMAKE = 'CROSS_COMPILE=${RISCV_PREBUILT_TOOLCHAIN} CC="${RISCV_PREBUILT_TOOLCHAIN}gcc" V=1'
EXTRA_OEMAKE += 'HOSTCC="${BUILD_CC} ${BUILD_CFLAGS} ${BUILD_LDFLAGS}"'

PACKAGECONFIG ??= "openssl"
# u-boot will compile its own tools during the build, with specific
# configurations (aka when CONFIG_FIT_SIGNATURE is enabled) openssl is needed as
# a host build dependency.
PACKAGECONFIG[openssl] = ",,openssl-native"

# Allow setting an additional version string that will be picked up by the
# u-boot build system and appended to the u-boot version.  If the .scmversion
# file already exists it will not be overwritten.
UBOOT_LOCALVERSION ?= ""


# returns all the elements from the src uri that are .cfg files
def find_cfgs(d):
    sources=src_patches(d, True)
    sources_list=[]
    for s in sources:
        if s.endswith('.cfg'):
            sources_list.append(s)

    return sources_list


do_configure () {
    oe_runmake -C ${S} O=${B} ${BOOTMCU_MACHINE}
    merge_config.sh -m .config ${@" ".join(find_cfgs(d))}
    cml1_do_configure
}

do_compile() {
    unset LDFLAGS
    unset CFLAGS
    unset CPPFLAGS

    if [ ! -e ${B}/.scmversion -a ! -e ${S}/.scmversion ]
    then
        echo ${UBOOT_LOCALVERSION} > ${B}/.scmversion
        echo ${UBOOT_LOCALVERSION} > ${S}/.scmversion
    fi

    oe_runmake -C ${S} O=${B} all
}

do_deploy() {
    sub_ver=$(cat ${B}/.subversion)
    install -d ${DEPLOYDIR}

    # spl
    install -m 644 ${B}/spl/u-boot-spl.dtb ${DEPLOYDIR}
    install -m 644 ${B}/spl/u-boot-spl-nodtb.bin ${DEPLOYDIR}
    install -m 644 ${B}/u-boot-spl.bin ${DEPLOYDIR}

    # spl binman
    install -m 644 ${BOOTMCU_FW_BINARY} ${DEPLOYDIR}
    install -m 644 ${BOOTMCU_FW_BINARY} ${DEPLOYDIR}/${BOOTMCU_FW_BINARY}-${sub_ver}
}

addtask deploy before do_build after do_compile

ALLOW_EMPTY:${PN} = "1"
