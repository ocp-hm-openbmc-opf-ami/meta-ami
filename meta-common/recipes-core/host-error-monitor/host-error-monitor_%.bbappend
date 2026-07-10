FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', ' file://0001-migrate-journal-events-to-dbus-bhs.patch', '', d)}"
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'evb-ast2600', ' file://0001-migrate-journal-events-to-dbus-2600evb.patch', '', d)}"
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', ' file://0001-Fix-boost-asio-io_service.hpp-deprecated-header.patch', '', d)}"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', '2700dcscm', ' file://0001-Fix-boost-asio-io_service.hpp-deprecated-header.patch', '', d)}"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', ' file://0001-UpGraded-the-Sdbusplus-version.patch', '', d)}"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', '2700dcscm', ' file://0001-UpGraded-the-Sdbusplus-version.patch', '', d)}"
