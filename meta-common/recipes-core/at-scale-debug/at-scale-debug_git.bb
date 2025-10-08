inherit obmc-phosphor-systemd

SUMMARY = "At Scale Debug Service"
DESCRIPTION = "At Scale Debug Service exposes remote JTAG target debug capabilities"

LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=8929d33c051277ca2294fe0f5b062f38"


inherit cmake pkgconfig
DEPENDS = "sdbusplus openssl libpam libgpiod safec"

do_configure[depends] += "virtual/kernel:do_shared_workdir"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/intel/firmware.bmc.openbmc.applications.at-scale-debug.git;protocol=ssh;branch=main"
SRCREV = "f418768bc8f3f99de85b8953176dd48a060c808c"

inherit useradd

USERADD_PACKAGES = "${PN}"

# add a special user asdbg
USERADD_PARAM:${PN} = "-u 9999 asd"

S = "${WORKDIR}/git"

SYSTEMD_SERVICE:${PN} += "com.intel.AtScaleDebug.service"

# Specify any options you want to pass to cmake using EXTRA_OECMAKE:
EXTRA_OECMAKE = "-DBUILD_UT=OFF"

CFLAGS:append = " -I ${STAGING_KERNEL_DIR}/include/uapi"
CFLAGS:append = " -I ${STAGING_KERNEL_DIR}/include"

# Copying the depricated header from kernel as a temporary fix to resolve build breaks.
# It should be removed later after fixing the header dependency in this repository.
SRC_URI += "file://asm/rwonce.h"
do_configure:prepend() {
    cp -r ${WORKDIR}/asm ${S}/asm
}
CFLAGS:append = " -I ${S}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://CtlASD.sh"

localdir = "/usr/local"
mybindir = "${localdir}/bin"

TLS_ENABLE = "no"

FILES:${PN} += "${localdir}/* ${mybindir}/* "

python () {
    # Replace the asd parameter by determining the "TLS_ENABLE"
    if d.getVar('TLS_ENABLE', True) == "no":
        d.setVar('TLS_ENABLE', "-u")
    elif d.getVar('TLS_ENABLE', True) == "yes":
        d.setVar('TLS_ENABLE', "")
}

do_install:append() {
    install -m 0755 -d ${D}${localdir}
    install -m 0755 -d ${D}${mybindir}
    install -d ${D}${systemd_unitdir}/system

    cp ${WORKDIR}/CtlASD.sh ${D}${mybindir}
    sed -e "s/\$TLS_ENABLE_FLAGE/${TLS_ENABLE}/g" ${WORKDIR}/com.intel.AtScaleDebug.service > ${D}${systemd_unitdir}/system/com.intel.AtScaleDebug.service
}

