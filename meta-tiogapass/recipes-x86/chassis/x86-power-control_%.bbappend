FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Backport the chassisSysIface typo fix.
SRC_URI:append = " file://0001-Fix-osSysIface-undeclared-typo.patch"

# Runtime MITAC/WIWYNN board detection for TiogaPass (port of upstream 0002-mitac-wiwynnbased-power.patch).
SRC_URI:append = " file://0002-tiogapass-runtime-mitac-wiwynn-detection.patch"
