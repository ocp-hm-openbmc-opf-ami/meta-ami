FILESEXTRAPATHS:append:= "${THISDIR}/files:"

SRC_URI:append:intel-ast2600 = "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '', ' file://flash-layout-update.cfg  ', d)}"
