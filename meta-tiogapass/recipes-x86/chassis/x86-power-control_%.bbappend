FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Backport the chassisSysIface typo fix.
SRC_URI:append = " file://0001-Fix-osSysIface-undeclared-typo.patch"

# Runtime MITAC/WIWYNN board detection for TiogaPass (port of upstream 0002-mitac-wiwynnbased-power.patch).
SRC_URI:append = " file://0002-tiogapass-runtime-mitac-wiwynn-detection.patch"

# ID_BUTTON/NMI_OUT are not named GPIO lines on TiogaPass (confirmed against
# the kernel's gpio-line-names); drop them so power-control doesn't exit(255)
# on find_line() failure.
SRC_URI:append = " file://0003-Remove-IdButton-and-NMIOut-for-TiogaPass.patch"
