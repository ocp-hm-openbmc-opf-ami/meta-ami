SRC_URI:remove:evb-imx95 = " \
    file://0006-Add-enhancement-for-certificate-errors.patch \
    file://0007-Removed-PrivateKey-Validation.patch \
    file://0015-clang-format-19-LF.patch \
"

FILESEXTRAPATHS:prepend:evb-imx95 := "${THISDIR}/${PN}:"
SRC_URI:append:evb-imx95 = " file://0016-validate-https-chain-key-length.patch"