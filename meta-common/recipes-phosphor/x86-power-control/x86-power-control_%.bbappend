FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI_EGS:append = "file://0001-Timer-Support-for-Chassis-Systems-Reset-EGS.patch"

SRC_URI_BHS:append = "file://0001-Timer-Support-for-Chassis-Systems-BHS.patch"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'egs', SRC_URI_EGS, '', d)}"
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', SRC_URI_BHS, '', d)}"
