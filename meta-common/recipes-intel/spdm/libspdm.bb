SUMMARY = "libspdm:dmtf"
DESCRIPTION = "Import the implementation of libspdm"
PR = "r1"

inherit pkgconfig cmake

DEPENDS += " \
            openssl\
            "
LICENSE = "DMTF"
LIC_FILES_CHKSUM = "file://LICENSE.md;md5=31d8b5ee5c0ad0dd6f6465d88d8caacd"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV ="269e520c0bd87c2b82f4455f7c3e9b3f87b8eca5"

SRC_URI += " \
  gitsm://github.com/DMTF/libspdm.git;protocol=https;nobranch=1 \
  file://0001-CMakeLists.txt.patch \
  file://0002-create-libspdm.patch \
  file://0003-Add-libspdm.pc.in.patch \
"
S = "${WORKDIR}/git"

OBMCGCC_OPTION = "${CC}"
OBMCGCC_OPTION:remove = "arm-openbmc-linux-gnueabi-gcc"

EXTRA_OECMAKE:append = " -DARCH=arm -DCMAKE_SYSTEM_NAME=Linux -DTOOLCHAIN=OPENBMC_GCC -DTARGET=Release -DCRYPTO=openssl -DCOMPILED_LIBCRYPTO_PATH="./os_stub/cryptlib_openssl" -DCOMPILED_LIBSSL_PATH="./os_stub/openssllib" -DMDEPKG_NDEBUG=1 -DFIPS_MODE=1 -DOBMCGCCOPTION='${OBMCGCC_OPTION}' "

