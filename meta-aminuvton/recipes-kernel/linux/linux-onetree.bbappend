FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:devkit-npcm845 = " \
    file://0001-identify-ami-devkit-npcm845.patch;apply=no \
    file://devkit-npcm845.cfg \
"

do_configure:append:devkit-npcm845() {
    patch --batch --forward --fuzz=0 -p1 -d ${S}/arch/arm64/boot/dts/nuvoton \
        < ${UNPACKDIR}/0001-identify-ami-devkit-npcm845.patch
}
