FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:devkit2700 = " file://0001-devkit-fan-identities.patch;patchdir=${UNPACKDIR}/EVB-2700"