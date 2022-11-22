SUMMARY = "NVME Daemon"
LICENSE = "CLOSED"

PR = "r1"

inherit systemd
inherit autotools pkgconfig cmake

DEPENDS += "autoconf-archive-native \
            systemd phosphor-logging phosphor-dbus-interfaces boost \
            "

DEPENDS :=" libmctp-intel mctpd mctp-wrapper mctpwplus  "
RDEPENDS:${PN} +="  mctpd mctp-wrapper mctpwplus "
SYSTEMD_SERVICE:${PN} = " nvme-mctp-pcie.service nvme-mctp-smbus.service"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

S = "${WORKDIR}/git/nvme/src"
SRC_URI = "git://git.ami.com/core/oe/common/firmware.management.bmc.openbmc-commercial.nvme-mgmt.git;protocol=https;branch=main"
SRCREV = "4ef8e8ef5147918867b65d23f9b4da680e640e4c"

#Change Application name, if it is different from recipe name.
APP_NAME = "nvme"


