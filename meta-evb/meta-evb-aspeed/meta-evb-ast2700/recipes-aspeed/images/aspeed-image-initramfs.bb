IMAGE_FSTYPES = "${INITRAMFS_FSTYPES}"

require recipes-core/images/core-image-minimal.bb

IMAGE_INSTALL:append = " \
        packagegroup-base \
        packagegroup-oss-apps \
        packagegroup-oss-extended \
        packagegroup-oss-libs \
        packagegroup-oss-intel-pmci \
        packagegroup-aspeed-apps \
        packagegroup-aspeed-crypto \
        packagegroup-aspeed-ssif \
        packagegroup-aspeed-mtdtest \
        packagegroup-aspeed-ktools \
        packagegroup-aspeed-usbtools \
        "
# uninstall packagegroup-oss-extra by default.
# IMAGE_INSTALL:append = " packagegroup-oss-extra "

# packagegroup for ast2600
IMAGE_INSTALL:append:aspeed-g6 = " \
        ${@bb.utils.contains('MACHINE_FEATURES', 'ast-ssp', 'packagegroup-aspeed-coprocessor-ssp', '', d)} \
        "

EXTRA_IMAGE_FEATURES:append = " \
        nfs-client \
        "
