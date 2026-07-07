SUMMARY = "SST Discovery and Control"
DESCRIPTION = "Out-of-band management of Intel Speed Select Technology"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"
SRC_URI = "git://git@github.com/intel-collab/firmware.bmc.openbmc.applications.speed-select.git;protocol=ssh;branch=main"
SRCREV = "7e4c41135fe59cb3b476a10b8a3e3073792aac74"
PV = "1.0+git${SRCPV}"

DEPENDS += "\
    phosphor-logging \
    phosphor-dbus-interfaces \
    boost \
    sdbusplus \
    libpeci \
    libpeciplus \
    libintel \
    "

S = "${UNPACKDIR}/git"

inherit meson systemd pkgconfig
EXTRA_OEMESON += "-Dtests=disabled -Dsst-libintel=false"
SYSTEMD_SERVICE:${PN} = "com.intel.SST.service"
