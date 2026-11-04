HOMEPAGE = "https://github.com/AspeedTech-BMC/u-boot"
SECTION = "bootloaders"
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

# We don't have 'u-boot-initial-env' target in our u-boot version
UBOOT_INITIAL_ENV = ""

