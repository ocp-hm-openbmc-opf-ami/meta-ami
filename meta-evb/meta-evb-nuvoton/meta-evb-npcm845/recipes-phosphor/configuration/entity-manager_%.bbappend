FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://EVB-NUVOTON/Nuvoton-thermal.json \
    file://EVB-NUVOTON/s997.json \
    "

do_install:append () {
    install -m 0644 -D ${UNPACKDIR}/EVB-NUVOTON/Nuvoton-thermal.json ${D}/usr/share/entity-manager/configurations
    install -m 0644 -D ${UNPACKDIR}/EVB-NUVOTON/s997.json ${D}/usr/share/entity-manager/configurations
}

