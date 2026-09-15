FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:ami-devkit = " file://0001-fan-entity-identities.patch;patchdir=${UNPACKDIR}/EVB-2600"