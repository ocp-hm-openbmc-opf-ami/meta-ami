FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI:append = " \
                 file://0001-Fix-Compilation-Werror-on-GZIP.patch \
                 "


