FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://0001-Revert-Add-workaround-for-several-i3c-services-288-3.patch \
    "

