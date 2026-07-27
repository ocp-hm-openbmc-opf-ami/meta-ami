FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Backport the sdbusplus API fix.
SRC_URI:append = " file://0050-Fix-common-code-for-new-sdbusplus-API.patch"
