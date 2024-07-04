FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON:append = " -Derror_cap=1000 -Derror_info_cap=2639"

SRCREV = "e8026679f89642e3336b8c5e495f6ab694988e7a"
SRC_URI += "\
    file://0001-Add-linear-and-circular-SEL-policy-support.patch \
    file://0002-Added-SEL-Enable-Disable-via-Set-BMC-Global-Enables-.patch \
"
