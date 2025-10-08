SUMMARY = "Virtual Media Service"
DESCRIPTION = "Virtual Media Service"

SRC_URI = "git://git@github.com/intel-bmc/firmware.bmc.openbmc.applications.virtual-media.git;protocol=ssh;branch=main"
SRCREV = "c2de0095742bbbbb5160791f1bb89417fcf66a4d"

S = "${WORKDIR}/git"
PV = "1.0+git${SRCPV}"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.VirtualMedia.service"

DEPENDS = "udev boost nlohmann-json systemd sdbusplus"

RDEPENDS:${PN} = "nbd-client (>=3.17) nbdkit"

inherit meson systemd pkgconfig

EXTRA_OEMESON += " -Dlegacy-mode=enabled"
EXTRA_OEMESON += " -Dtests=disabled"

FULL_OPTIMIZATION = "-Os -pipe -flto -fno-rtti"
