SUMMARY = "PECI Library Plus"
DESCRIPTION = "PECI Library Plus"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"
PV = "0.1+git${SRCPV}"

DEPENDS:append = " mctpwplus sdbusplus phosphor-logging"

SRC_URI = "git://git@github.com/intel-collab/firmware.bmc.openbmc.libraries.libpeciplus.git;protocol=ssh;branch=main"
SRCREV = "e2eb3f012d0ab5427f355bc83ef1f3d07e36d6c4"

PACKAGECONFIG ??= ""
PACKAGECONFIG[dbus-raw-peci] = "-Draw-peci='enabled',-Draw-peci='disabled'"
PACKAGECONFIG[peci-espi] = "-Dpeci-espi='enabled',-Dpeci-espi='disabled',libespi"

S = "${UNPACKDIR}/git"
SYSTEMD_SERVICE:${PN} += "${@bb.utils.contains('PACKAGECONFIG', 'dbus-raw-peci', 'com.intel.peci.service', '', d)}"

inherit meson pkgconfig systemd
