FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/host-error-monitor.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "65608c0efe7e5e5aabb37d5334719d62fe55e1f1"


SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', ' file://0001-Fix-boost-asio-io_service.hpp-deprecated-header.patch', '', d)}"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', '2700dcscm', ' file://0001-Fix-boost-asio-io_service.hpp-deprecated-header.patch', '', d)}"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', ' file://0001-UpGraded-the-Sdbusplus-version.patch', '', d)}"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', '2700dcscm', ' file://0001-UpGraded-the-Sdbusplus-version.patch', '', d)}"
