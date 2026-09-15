FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:devkit-npcm845 = " file://0001-configure-devkit-npcm845-power.json.patch;apply=no"

do_install:append:devkit-npcm845() {
    patch --batch --forward --fuzz=0 ${D}${datadir}/${BPN}/power-config-host0.json \
        < ${UNPACKDIR}/0001-configure-devkit-npcm845-power.json.patch
}
