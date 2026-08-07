FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += "git://git.ami.com/core/ami-bmc/one-tree/core/host-error-monitor.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "ac0e7be0ac67c69c7e7bd06d0c3bb8a60abfb5bc"


SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', ' file://0001-Fix-boost-asio-io_service.hpp-deprecated-header.patch', '', d)}"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', '2700dcscm', ' file://0001-Fix-boost-asio-io_service.hpp-deprecated-header.patch', '', d)}"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', ' file://0001-UpGraded-the-Sdbusplus-version.patch', '', d)}"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', '2700dcscm', ' file://0001-UpGraded-the-Sdbusplus-version.patch', '', d)}"
