FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:2700-dcscm-features = " \
    file://0001-2700-DCSCM-BHS-libmctp-Fixes.patch \
"
