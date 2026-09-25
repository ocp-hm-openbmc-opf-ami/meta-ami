DESCRIPTION = "Linux Kernel for imx"
SECTION = "kernel"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

PE = "1"
PV = "${LINUX_VERSION}+git${SRCPV}"
KERNEL_VERSION_SANITY_SKIP = "1"

inherit siteinfo
require recipes-kernel/linux/linux-yocto.inc

SRC_URI += " \
    "

KCONFIG_MODE = "--alldefconfig"
KBUILD_DEFCONFIG ?= "${BMC_LINUX_DEFCONFIG}"

LINUX_VERSION_EXTENSION ?= ""

KERNEL_MODULE_AUTOLOAD += "${@bb.utils.contains("MACHINE_FEATURES", "pitft28r", "stmpe-ts", "", d)}"

KERNEL_EXTRA_ARGS += "LOADADDR=${UBOOT_ENTRYPOINT}"

UBOOT_ENTRYPOINT =       "0x00008000"
UBOOT_LOADADDRESS =      "0x00008000"
