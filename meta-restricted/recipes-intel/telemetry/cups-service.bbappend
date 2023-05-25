FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI_BHS:append = " \
    file://bhs/0001-Adding-missing-dbus-properties-for-cups.patch \
    file://bhs/0002-Add-Current-PowerState-monitoring-before-CPU-detecti.patch"

SRC_URI_EGS:append = " \
    file://egs/0001-Add-Current-PowerState-monitoring-before-CPU-detect_egs.patch \
    file://egs/0002-Adding-missing-dbus-properties-for-cups.patch"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'egs', SRC_URI_EGS, '', d)}"
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', SRC_URI_BHS, '', d)}"

