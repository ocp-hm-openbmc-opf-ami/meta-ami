SUMMARY = "PLDM Stack"
DESCRIPTION = "Implementation of the PLDM specifications"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"
PR = "r1"
PV = "1.0+git${SRCPV}"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
#For LIBPLDMRESPONDER Feature
FILES:${PN} += "${datadir}/pldm" 

# Primary repository revision
SRCREV = "017d70397cbbd80abeea775df3d3cbae627efc24"
SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/ot-pldm.git;protocol=https;branch=main;"

inherit meson pkgconfig
inherit systemd
DEPENDS += "function2"
DEPENDS += "systemd"
DEPENDS += "sdeventplus"
DEPENDS += "phosphor-dbus-interfaces"
DEPENDS += "phosphor-logging"
DEPENDS += "nlohmann-json"
DEPENDS += "cli11"
DEPENDS += "openssl"
DEPENDS += "ot-libpldm"
DEPENDS += "libbej"
DEPENDS += "${@bb.utils.contains('ENABLE_COMMUNITY_MCTP_KERNEL_MODE', '1', ' mctp', ' libmctp', d)}"
RDEPENDS:${PN} += " bash"
RDEPENDS:${PN} += " pldm-oem-hooks"
RDEPENDS:${PN} += " ot-libpldm"
RDEPENDS:${PN} += " libbej"
RDEPENDS:${PN} += "${@bb.utils.contains('ENABLE_COMMUNITY_MCTP_KERNEL_MODE', '1', ' mctp', ' libmctp', d)}"

S = "${WORKDIR}/git"
SRC_URI += " file://pldmd.service"
SYSTEMD_SERVICE:${PN} += "pldmd.service"

EXTRA_OEMESON += " \
    -Ddebug-token=disabled \
    -Dinstance-id-expiration-interval=20 \
    -Dplatform-prefix='' \
    -Dtests=disabled \
    -Dfw-update-skip-package-size-check=enabled \
    -Dfw-debug=enabled \
    -Dlibpldmresponder=enabled \
    -Dresponse-time-out=4800 \
    -Dpldm-type2=enabled \
    -Dpldm-type4=enabled \
    -Dot-extension=enabled \
    -Domit-heartbeat=enabled \
    "
EXTRA_OEMESON += "${@bb.utils.contains('ENABLE_COMMUNITY_MCTP_KERNEL_MODE', '1', ' -Dtransport-implementation=\'af-mctp\'', ' -Dtransport-implementation=\'mctp-demux\'', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FEATURES','onetree-rtp',' -Dpldm-type6=enabled','',d)}"

do_install:append() {
   install -d ${D}${includedir}/ot-pldm/libpldmresponder/
   install -d ${D}${includedir}/ot-pldm/pldmd
   cp -r ${S}/libpldmresponder/types.hpp ${D}${includedir}/ot-pldm/libpldmresponder/
   cp -r ${S}/pldmd/handler.hpp ${D}${includedir}/ot-pldm/pldmd/
}

do_install:append() {
    rm -f ${D}${nonarch_base_libdir}/systemd/system/pldmd.service
    install -m 0644 ${UNPACKDIR}/pldmd.service  ${D}${nonarch_base_libdir}/systemd/system/
}
