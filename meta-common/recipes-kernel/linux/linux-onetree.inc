DESCRIPTION = "Linux kernel for Aspeed and Nuvoton NPCM7xx"
SECTION = "kernel"
LICENSE = "GPL-2.0-only"
PROVIDES += "virtual/kernel"

PREFERRED_PROVIDER_virtual/kernel = "linux-onetree"

KCONFIG_MODE="--alldefconfig"
KERNEL_VERSION_SANITY_SKIP="1"
KERNEL_EXTRA_ARGS = "V=1"

KERNEL_VERSION_SANITY_SKIP="1"

inherit kernel
require recipes-kernel/linux/linux-yocto.inc

# From 5.6+ the COPYING file changed
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"
SRC_URI:append:evb-ast2600 = " \
             file://defconfig \
	     "
SRC_URI:append:intel-ast2600 = " \
             file://defconfig \
	     "
SRC_URI:append:amd-chalupa = " \
             file://defconfig \
	     "
SRC_URI:append:evb-ast2600-rm = " \
             file://defconfig \
	     "
LINUX_VERSION_EXTENSION ?= "-${SRCREV}"
KERNEL_LOCALVERSION = "-ami"

PV = "${LINUX_VERSION}+git${SRCPV}"

# Do not install the kernel image into rootfs at /boot directory
RRECOMMENDS:${KERNEL_PACKAGE_NAME}-base = ""

SRC_URI:append:npcm7xx = " file://defconfig "
SRC_URI:append:npcm8xx = " file://npcm8xx_defconfig "

UBOOT_MKIMAGE:append:npcm8xx = " -E -B 8"

# From 4.16+ the COPYING file changed
LIC_FILES_CHKSUM:evb-npcm845 = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

