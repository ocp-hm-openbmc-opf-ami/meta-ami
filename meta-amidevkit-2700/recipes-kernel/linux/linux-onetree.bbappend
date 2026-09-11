FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:devkit2700 = " file://0001-configure-ast2700-devkit-dts.patch;apply=no"

do_configure:append:devkit2700() {
    patch --batch --forward --fuzz=0 -p2 -d ${S}/arch/arm64/boot/dts/aspeed \
        < ${UNPACKDIR}/0001-configure-ast2700-devkit-dts.patch
}