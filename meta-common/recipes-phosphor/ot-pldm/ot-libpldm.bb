LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

LIBPLDM_ABI_DEVELOPMENT = "deprecated,stable,testing"
LIBPLDM_ABI_MAINTENANCE = "stable,testing"
LIBPLDM_ABI_PRODUCTION = "deprecated,stable"
PACKAGECONFIG ??= "abi-production"
PACKAGECONFIG[abi-development] = "-Dabi=${LIBPLDM_ABI_DEVELOPMENT},,,"
PACKAGECONFIG[abi-maintenance] = "-Dabi=${LIBPLDM_ABI_MAINTENANCE},,,"
PACKAGECONFIG[abi-production] = "-Dabi=${LIBPLDM_ABI_PRODUCTION},,,"
PACKAGECONFIG[oem-ibm] = "-Doem-ibm=enabled,-Doem-ibm=disabled,,"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
FILES:${PN} += "${datadir}/libpldm"

SRCREV = "291cd44f00f1ef82590dec7bbf1f000ab2391718"
SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/ot-libpldm.git;protocol=https;branch=main;"

# Due to release rule, isolate new git repo to prevent customer from fetch failed.
# Temporarily use tarball for customer build.
# TODO: Remove the tarball and use git repo after OneTree-3.1 offical release.
SRC_URI = "file://ot-libpldm.tar.gz"

S = "${WORKDIR}/git"

inherit meson

EXTRA_OEMESON:append = " -Dtests=disabled"
