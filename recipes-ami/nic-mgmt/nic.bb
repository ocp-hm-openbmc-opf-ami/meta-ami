SUMMARY = "NIC Daemon"
LICENSE = "CLOSED"
PR = "r1"

inherit systemd
inherit autotools pkgconfig cmake

DEPENDS += "autoconf-archive-native \
            systemd phosphor-logging phosphor-dbus-interfaces boost \
            "
DEPENDS +=" libmctp-intel mctpd mctp-wrapper"
RDEPENDS:${PN} +="  mctpd mctp-wrapper"

SYSTEMD_SERVICE:${PN} = "nic-mctp-smbus.service nic-mctp-pcie.service"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

S = "${WORKDIR}/git/nic/src"
SRC_URI = "git://git.ami.com/core/oe/advanced-features/firmware.management.bmc.openbmc-commercial.nic-mgmt.git;protocol=https"
SRCREV = "3461bdc2e825dd86fdb80ed8cf3c400a524e306b"

#Change Application name, if it is different from recipe name.
APP_NAME = "nic"
