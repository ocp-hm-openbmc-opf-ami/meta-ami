DESCRIPTION = "Linux kernel for Aspeed and Nuvoton NPCM7xx"
SECTION = "kernel"
LICENSE = "GPL-2.0-only"
PROVIDES += "virtual/kernel"

PREFERRED_PROVIDER_virtual/kernel = "linux-onetree"

KCONFIG_MODE = "--alldefconfig"
KERNEL_VERSION_SANITY_SKIP = "1"
KERNEL_EXTRA_ARGS = "V=1"

KERNEL_VERSION_SANITY_SKIP = "1"

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
SRC_URI:append:evb-ast2600-cdu = " \
             file://defconfig \
             "
SRC_URI:append:evb-ast2600-psm = " \
             file://defconfig \
             "
LINUX_VERSION_EXTENSION ?= "-${SRCREV}"
KERNEL_LOCALVERSION = "-ami"

# Empty when SRCREV is not a fixed commit (unset/INVALID/AUTOREV), giving "<ver>-ami".
def onetree_kernel_localversion(d):
    import re
    rev = d.getVar('SRCREV') or ''
    return '-' + rev[:7] if re.fullmatch(r'[0-9a-f]{40}', rev) else ''

# Pin localversion to SRCREV; the post-patch HEAD hash used by obmc-phosphor-kernel-version
# changes on every rebuild and breaks sstate/pkgdata consistency (kernel-<ver> not found in do_rootfs).
do_set_local_version() {
    localver="${@onetree_kernel_localversion(d)}"
    if [ -z "${localver}" ]; then
        bbwarn "SRCREV '${@d.getVar('SRCREV') or ''}' is not a commit hash; kernel version has no revision suffix"
    fi
    # KERNEL_LOCALVERSION (-ami) is appended by kernel.bbclass via the exported LOCALVERSION, not here
    # devtool (externalsrc) builds skip sstate, so the live HEAD hash is safe and identifies the dev tree
    if [ -n "${@d.getVar('EXTERNALSRC') or ''}" ]; then
        head=$(git -C ${S} rev-parse --short HEAD 2>/dev/null || true)
        localver="${localver}-devtool${head:+-$head}"
    fi
    sed -i '/CONFIG_LOCALVERSION/d' ${B}/.config
    echo "CONFIG_LOCALVERSION=\"${localver}\"" >> ${B}/.config
    echo '# CONFIG_LOCALVERSION_AUTO is not set' >> ${B}/.config
}
addtask set_local_version before do_configure after do_kernel_configme

PV = "${LINUX_VERSION}+git${SRCPV}"

ERROR_QA:remove = " buildpaths "
WARN_QA:append = " buildpaths "

# Do not install the kernel image into rootfs at /boot directory
RRECOMMENDS:${KERNEL_PACKAGE_NAME}-base = ""

SRC_URI:append:npcm7xx = " file://defconfig "
SRC_URI:append:npcm8xx = " file://npcm8xx_defconfig "

UBOOT_MKIMAGE:append:npcm8xx = " -E -B 8"

# From 4.16+ the COPYING file changed
LIC_FILES_CHKSUM:evb-npcm845 = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

SRC_URI += "file://0004-Fix-I2C-Coverity-for-linux-onetree.patch \
            file://0004-Fix-common-kernel-I2C-patch-error-in-OT-AMD.patch \
            file://0005-Add-the-M-Hold-patch-and-I2C-Driver-change-from-INTEL.patch \
            file://0006-Fixed-the-bootup-issue.patch \
            "

SRC_CPLD_SPI = " file://cpld-spidev.cfg \
                 file://0006-enable-spidev-in-driver-file.patch \
		 file://0001-spi-aspeed-smc-enable-cpld-spidev-transfers.patch \
               "
SRC_URI:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-fwupdate', SRC_CPLD_SPI,'', d)}"

SRC_IPMI_SSIF = " file://0006-Add-SSIF-and-SBMR-support.patch \
                "
SRC_URI:append = "${@bb.utils.contains('IMAGE_FEATURES', 'onetree-ipmi-ssif', SRC_IPMI_SSIF,'', d)}"

# ABR mode detection patch for AST2600
SRC_URI_ABR_PATCH = "file://0001-spi-aspeed-Add-ABR-mode-detection-support-for-AST260.patch \
                     file://0007-dual-image-abr-mode-fix.patch \
                    "

# Apply to evb-ast2600
SRC_URI:append:evb-ast2600 = " \
    ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-hw-failsafe-boot', \
        '${SRC_URI_ABR_PATCH}', '', d)} \
"

# Apply to intel-ast2600
SRC_URI:append:intel-ast2600 = " \
    ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-hw-failsafe-boot', \
        '${SRC_URI_ABR_PATCH}', '', d)} \
"
