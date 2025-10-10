FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:2700-dcscm-features = " \
    file://0001-Fix-for-2700-DCSCM-BHS-build.patch \
    "

