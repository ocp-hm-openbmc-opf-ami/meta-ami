SUMMARY = "U-Boot bootloader fw_printenv/setenv utilities"

OVERRIDES .= ":uboot-flash-${FLASH_SIZE}"

# We don't have 'u-boot-initial-env' target in our u-boot version
UBOOT_INITIAL_ENV = ""

PV = "v2019.04+git${SRCPV}"

require recipes-bsp/u-boot/u-boot-configure.inc

DEPENDS += "flex-native bison-native xxd-native"

LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=30503fd321432fc713238f582193b78e"
PE = "1"

BRANCH = "onetree-dev-v2019.04"
SRC_URI = "git://git.ami.com/core/ami-bmc/base-tech/u-boot-onetree.git;protocol=https;branch=onetree-dev-v2019.04 "

SRCREV = "6a2dc9a722fecb677db20d78c0ded85afc1e90c7"

SRC_URI:append:uboot-flash-32768 = " file://u-boot_flash_32M.cfg"
SRC_URI:append:uboot-flash-65536 = " file://u-boot_flash_64M.cfg"
SRC_URI:append:uboot-flash-131072 = " file://u-boot_flash_128M.cfg"

S = "${WORKDIR}/git"
B = "${WORKDIR}/build"
do_configure[cleandirs] = "${B}"

DEPENDS += "mtd-utils"

PROVIDES += "u-boot-fw-utils"
RPROVIDES:${PN} += "u-boot-fw-utils"

# The 32MB NOR and 64MB NOR layouts use the same configuration
SRC_URI += "file://fw_env_flash_nor.config"
SRC_URI += "file://fw_env_ast2600_mmc.config"

ENV_CONFIG_FILE = "fw_env_flash_nor.config"
ENV_CONFIG_FILE:df-phosphor-mmc = "fw_env_ast2600_mmc.config"

INSANE_SKIP:${PN} = "already-stripped"
EXTRA_OEMAKE:class-target = 'CROSS_COMPILE=${TARGET_PREFIX} CC="${CC} ${CFLAGS} ${LDFLAGS}" HOSTCC="${BUILD_CC} ${BUILD_CFLAGS} ${BUILD_LDFLAGS}" V=1'
EXTRA_OEMAKE:class-cross = 'HOSTCC="${CC} ${CFLAGS} ${LDFLAGS}" V=1'

inherit uboot-config

do_compile () {
	oe_runmake envtools
}

do_install () {
	install -d ${D}${base_sbindir}
	install -m 755 ${B}/tools/env/fw_printenv ${D}${base_sbindir}/fw_printenv
	ln -sf fw_printenv ${D}${base_sbindir}/fw_setenv

	install -d ${D}${sysconfdir}
	install -m 644 ${UNPACKDIR}/${ENV_CONFIG_FILE} ${D}${sysconfdir}/fw_env.config
}

do_install:class-cross () {
	install -d ${D}${bindir_cross}
	install -m 755 ${B}/tools/env/fw_printenv ${D}${bindir_cross}/fw_printenv
	ln -sf fw_printenv ${D}${bindir_cross}/fw_setenv
}

SYSROOT_DIRS:append:class-cross = " ${bindir_cross}"

PACKAGE_ARCH = "${MACHINE_ARCH}"
BBCLASSEXTEND = "cross"
