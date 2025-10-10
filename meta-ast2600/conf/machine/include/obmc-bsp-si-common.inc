#@TYPE: Machine
#@NAME: OpenBMC
#@DESCRIPTION: Common machine configuration for OpenBMC chips

MACHINE_EXTRA_RRECOMMENDS = " kernel-modules"
EXTRA_IMAGEDEPENDS += "u-boot"

IMAGE_FSTYPES += "squashfs-xz"
IMAGE_FSTYPES += "mtd-auto"
INITRAMFS_FSTYPES = "squashfs-xz"
# FIXME: There is an issue in Yocto where the command-specific EXTRA_IMAGECMD
# doesn't work anymore, so as a temporary workaround to unblock the upstream
# sync, this removes the 'squashfs-xz' and makes the parameters generic. This
# seems to work because we don't have any other IMAGE_CMD commands that we use.
# But it could cause issues if we ever need to use another IMAGE_CMD, so we
# should correct this as soon as possible after we get a fix from Yocto.
EXTRA_IMAGECMD:append = "-processors ${BB_NUMBER_THREADS} -b 262144 -Xdict-size 100% -Xbcj arm"
#This is the original line for reference
#EXTRA_IMAGECMD:squashfs-xz:append = "-processors ${BB_NUMBER_THREADS} -b 262144 -Xdict-size 100% -Xbcj arm"

KERNEL_CLASSES ?= "kernel-fitimage"
KERNEL_IMAGETYPES ?= "fitImage"
KERNEL_EXTRA_ARGS += "LOADADDR=${UBOOT_ENTRYPOINT}"

UBOOT_SUFFIX ?= "bin"

MACHINEOVERRIDES =. "openbmc:"

OBMC_PHOSPHOR_IMAGE_OVERLAY= "1"
OBMC_IMAGE_EXTRA_INSTALL:append = "u-boot-fw-utils-aspeed-sdk"

IMAGE_CLASSES += "image_types image_types_phosphor_auto qemuboot"

# do not generate an initramfs; use the above squashfs-xz as an initrd instead
INITRAMFS_FSTYPES = ""
INITRAMFS_CTYPE = ""
INITRAMFS_IMAGE = ""

MACHINE_FEATURES_BACKFILL_CONSIDERED = "qemu-usermode"

KERNEL_IMAGETYPES += "zImage"

# runqemu
QB_SYSTEM_NAME = "qemu-system-arm"
QB_DEFAULT_FSTYPE = "mtd"
QB_ROOTFS_OPT = "-drive file=@ROOTFS@,format=raw,if=mtd"
QB_MACHINE = "-M intel-ast2600"
QB_OPT_APPEND += " -nographic -serial mon:stdio -serial none"
QB_OPT_APPEND += " -global driver=aspeed.gpio-ast2600,property=gpioC0,value=true"
QB_NETWORK_DEVICE = "-net nic,macaddr=C0:FF:EE:00:00:02,model=ftgmac100"
QB_DEFAULT_KERNEL = "none"
QB_RNG = ""
QB_MEM = "1024"
