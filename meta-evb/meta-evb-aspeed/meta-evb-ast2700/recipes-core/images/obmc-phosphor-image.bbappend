FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
IMAGE_INSTALL:append = " \
        libmctp \
        entity-manager \
        virtual-media \
        "

IMAGE_INSTALL:append = " \
        packagegroup-oss-apps \
        packagegroup-oss-libs \
        packagegroup-oss-intel-pmci \
        packagegroup-aspeed-obmc-apps \
        packagegroup-aspeed-apps \
        packagegroup-aspeed-crypto \
        packagegroup-aspeed-ssif \
        packagegroup-aspeed-obmc-inband \
        ${@bb.utils.contains('MACHINE_FEATURES', 'ast-ssp', 'packagegroup-aspeed-ssp', '', d)} \
        packagegroup-aspeed-mtdtest \
        packagegroup-aspeed-usbtools \
        ${@bb.utils.contains('DISTRO_FEATURES', 'tpm', \
            bb.utils.contains('MACHINE_FEATURES', 'tpm2', 'packagegroup-security-tpm2', '', d), \
            '', d)} \
        packagegroup-aspeed-ktools \
        "

# uninstall packagegroup-oss-extra by default.
# IMAGE_INSTALL:append = " packagegroup-oss-extra "

# remove from AST25xx series rofs as the free space of AST25xx rofs is not enough.
IMAGE_INSTALL:remove:aspeed-g5 = " \
        packagegroup-aspeed-ktools \
        packagegroup-oss-extra \
        "

# packagegroup for ast2700
IMAGE_INSTALL:append:aspeed-g7 = " \
        packagegroup-oss-extended \
        "

EXTRA_IMAGE_FEATURES:append = " \
        nfs-client \
        ${@bb.utils.contains('DISTRO_FEATURES', 'obmc-ubi-fs', 'read-only-rootfs-delayed-postinsts', '', d)} \
        ${@bb.utils.contains('DISTRO_FEATURES', 'phosphor-mmc', 'read-only-rootfs-delayed-postinsts', '', d)} \
        "

# Enable spi-nor-ecc.inc and unmask below to generate an image-rwfs with cleanmarker size set to 16.
#OVERLAY_MKFS_OPTS:spi-nor-ecc = " -c 16 -e 262144 --pad=${RWFS_SIZE} "

# defer the inheritance of image_types_phosphor_aspeed to ensure it overrides image_types_phosphor
inherit_defer image_types_phosphor_aspeed
#inherit image_types_phosphor_aspeed
