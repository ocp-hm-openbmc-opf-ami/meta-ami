FILESEXTRAPATHS:prepend := "${THISDIR}/settings:"


SRC_URI += " \
           file://0001-Add-SEL-policy-chacher.patch \
"

SRC_URI_NON_PFR = "file://0002-moving-cpld-inventory-for-non-pfr-to-software-manage.patch "
SRC_URI:append = " ${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '', SRC_URI_NON_PFR, d)}"
