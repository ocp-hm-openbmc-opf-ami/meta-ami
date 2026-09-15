FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:devkit-npcm845 = " \
    file://0001-configure-devkit-npcm845-entities.patch;apply=no \
    file://0002-configure-devkit-npcm845-thermal.patch;apply=no \
"

do_install:append:devkit-npcm845() {
    patch --batch --forward --fuzz=0 ${D}${datadir}/${BPN}/configurations/nuvoton/npcm8xx_evb.json \
        < ${UNPACKDIR}/0001-configure-devkit-npcm845-entities.patch
    patch --batch --forward --fuzz=0 ${D}${datadir}/${BPN}/configurations/Nuvoton-thermal.json \
        < ${UNPACKDIR}/0002-configure-devkit-npcm845-thermal.patch
}