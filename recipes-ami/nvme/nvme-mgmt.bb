SUMMARY = "NVME Mgt Daemon"
LICENSE = "CLOSED"
PR = "r1"

inherit systemd
inherit autotools pkgconfig cmake

DEPENDS += "autoconf-archive-native \
            systemd phosphor-logging phosphor-dbus-interfaces boost \
            "

DEPENDS +=" nvme pmci-launcher pldmd"
RDEPENDS:${PN} +=" nvme pmci-launcher pldmd"
SYSTEMD_SERVICE:${PN} = "nvme-mgmt.service "
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

S = "${WORKDIR}/git/nvme-mgmt/src"
SRC_URI = "git://git.ami.com/core/oe/common/firmware.management.bmc.openbmc-commercial.nvme-mgmt.git;protocol=https;branch=main"
SRCREV = "69f9455c469881ccc7b9d8ffbe288ac57ad9b976"

#Change Application name, if it is different from recipe name.
APP_NAME = "nvme-mgmt"

