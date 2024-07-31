SUMMARY = "A /dev/crypto device driver kernel module"
DESCRIPTION = "A /dev/crypto device driver kernel module, \
equivalent to those in OpenBSD or FreeBSD. The main idea is \
to access of existing ciphers in kernel space from userspace, \
thus enabling the re-use of a hardware implementation of a cipher."
SECTION = "kernel/modules"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

PR = "r0"
PV = "v00.01.00+git"

DEPENDS = "virtual/kernel"

S = "${WORKDIR}/git"

BRANCH="aspeed-master-v1.12"
SRC_URI = "git://github.com/AspeedTech-BMC/cryptodev.git;protocol=https;branch=${BRANCH}"
# Tag for v00.01.00
SRCREV = "c243f6c056ea69d2fe51927446f8e138c5004af3"

inherit module

EXTRA_OEMAKE = 'KERNEL_DIR="${STAGING_KERNEL_DIR}" DESTDIR="${D}"'
CLEANBROKEN = "1"

# The inherit of module.bbclass will automatically name module packages with
# "kernel-module-" prefix as required by the oe-core build environment.

RPROVIDES:${PN} += "kernel-module-cryptodev"
