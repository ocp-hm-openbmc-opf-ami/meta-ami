FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

S = "${UNPACKDIR}/git"

SRC_URI:append = " \
    file://0001-CMakeLists64.patch \
    file://0006-cryptlib_ext.patch \
    file://0007-Add-sample-SPDM-1.2-APIs-to-sign-CSR.patch \
"

SRC_URI:remove = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'oks',' file://0001-CMakeLists64.patch','',d)}"

EXTRA_OECMAKE:remove = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'ast2700-sdk-layer','-DARCH=arm','',d)}"
EXTRA_OECMAKE:append = " ${@bb.utils.contains('BBFILE_COLLECTIONS', 'ast2700-sdk-layer','-DARCH=aarch64','',d)}"
EXTRA_OECMAKE:remove = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'ast2700-pfr-layer','-DARCH=arm','',d)}"
EXTRA_OECMAKE:append = " ${@bb.utils.contains('BBFILE_COLLECTIONS', 'ast2700-pfr-layer','-DARCH=aarch64','',d)}"
EXTRA_OECMAKE:remove = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'amd-venice','-DARCH=arm','',d)}"
EXTRA_OECMAKE:append = " ${@bb.utils.contains('BBFILE_COLLECTIONS', 'amd-venice','-DARCH=aarch64','',d)}"