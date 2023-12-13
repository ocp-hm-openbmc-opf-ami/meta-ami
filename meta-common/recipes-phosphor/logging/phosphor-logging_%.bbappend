FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON:append = " -Derror_cap=1000 -Derror_info_cap=2639"

SRC_URI += "\
    file://0001-Add-linear-and-circular-SEL-policy-support.patch \
"
