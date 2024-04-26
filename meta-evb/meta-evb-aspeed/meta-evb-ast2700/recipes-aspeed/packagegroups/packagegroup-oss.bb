SUMMARY = "Packagegroup for Open Source"

PR = "r1"

PACKAGE_ARCH="${TUNE_PKGARCH}"

inherit packagegroup

PROVIDES = "${PACKAGES}"

PACKAGES = " \
    ${PN}-apps \
    ${PN}-libs \
    ${PN}-intel-pmci \
    ${PN}-extended \
    ${PN}-extra \
    "

# The size of fio is very large because its dependencies
# includes python3-core
# The size of fio and python3-core are 10MB.
SUMMARY:${PN}-apps = "Open Source Applications"
RDEPENDS:${PN}-apps = " \
    gperf \
    iperf3 \
    pciutils \
    ethtool \
    i3c-tools \
    i2c-tools \
    dhrystone \
    nbd-client \
    iozone3 \
    ncsi-netlink \
    hdparm \
    e2fsprogs-mke2fs \
    nvme-cli \
    ${@d.getVar('PREFERRED_PROVIDER_u-boot-fw-utils', True) or 'u-boot-fw-utils'} \
    aer-inject \
    fio \
    mctp \
    "

#SUMMARY:${PN}-intel-pmci = "Open Source Intel PMCI Applications"
#RDEPENDS:${PN}-intel-pmci = " \
#    libmctp-intel-test \
#    "

# Only install in AST26xx and AST27xx series rofs as the free space of AST25xx rofs is not enough.
RDEPENDS:${PN}-apps:remove:aspeed-g5 = " \
    i3c-tools \
    iozone3 \
    hdparm \
    fio \
    "

RDEPENDS:${PN}-apps:append:cypress-s25hx = " \
    mtd-utils \
    "

SUMMARY:${PN}-libs = "Open Source Library"
RDEPENDS:${PN}-libs = " \
    libgpiod \
    libgpiod-tools \
    "
