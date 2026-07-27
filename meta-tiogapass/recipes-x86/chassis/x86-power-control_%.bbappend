FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Backport the chassisSysIface typo fix.
SRC_URI:append = " file://0001-Fix-osSysIface-undeclared-typo.patch"
