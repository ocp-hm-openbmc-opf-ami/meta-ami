FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON:append = " -Derror_cap=1000 -Derror_info_cap=2639"

SRCREV = "972dd4f62890cf676c80270636ad63a7ca9a590a"
SRC_URI += "\
    file://0001-Add-linear-and-circular-SEL-policy-support.patch \
"
