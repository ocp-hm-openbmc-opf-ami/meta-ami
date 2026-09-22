
LINUX_VERSION ?= "6.12.49"
LINUX_RPI_BRANCH ?= "rpi-6.12.y"
LINUX_RPI_KMETA_BRANCH ?= "yocto-6.12"

SRCREV_machine = "${BMC_LINUX_SRCREV}"
SRCREV_meta = "1f6ab68a1d86836bf1b82b791df03da3cfeacb3f"

KERNEL_SRC = "${BMC_LINUX_SRC};branch=${BMC_LINUX_BRANCH}"
SRCBRANCH = "${BMC_LINUX_BRANCH}"
SRCREV = "${BMC_LINUX_SRCREV}"

PREFERRED_PROVIDER_virtual/kernel = "linux-nxp"

KMETA = "kernel-meta"

SRC_URI = " \
    ${KERNEL_SRC} \
    git://git.yoctoproject.org/yocto-kernel-cache;type=kmeta;name=meta;branch=${LINUX_RPI_KMETA_BRANCH};destsuffix=${KMETA} \
    "

require linux-nxp.inc

KERNEL_DTC_FLAGS += "-@ -H epapr"
