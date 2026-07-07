SUMMARY = "NVMe MI Daemon"
DESCRIPTION = "Implementation of NVMe MI daemon"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/nvme-mi-daemon.git;protocol=https;branch=main"

SRC_URI:append =  " file://0001-add-cmath-header.patch \
		    file://0002-fix-mctpwplus-api.patch "

SRCREV = "dc09e309ac10a17e59c92308a99b78de72924c25"
S = "${UNPACKDIR}/git"
PV = "1.0+git${SRCPV}"

inherit meson systemd pkgconfig

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.nvme-mi.service"
DEPENDS = "boost sdbusplus systemd phosphor-logging mctpwplus googletest nlohmann-json"

EXTRA_OEMESON = "-Dyocto_dep='enabled'"
