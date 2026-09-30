FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += "git://github.com/ocp-hm-openbmc-opf-ami/host-error-monitor;branch=integrate-onetree-latest;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "5706cbb67498dc189080605e2b4da9bfe2f474fd"


SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', ' file://0001-Fix-boost-asio-io_service.hpp-deprecated-header.patch', '', d)}"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', '2700dcscm', ' file://0001-Fix-boost-asio-io_service.hpp-deprecated-header.patch', '', d)}"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', ' file://0001-UpGraded-the-Sdbusplus-version.patch', '', d)}"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', '2700dcscm', ' file://0001-UpGraded-the-Sdbusplus-version.patch', '', d)}"
