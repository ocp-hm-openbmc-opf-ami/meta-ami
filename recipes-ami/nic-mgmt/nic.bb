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
SRCREV = "dd054bbd62eaf84e5a356beda5246f969864a11e"

#Change Application name, if it is different from recipe name.
APP_NAME = "nic"
