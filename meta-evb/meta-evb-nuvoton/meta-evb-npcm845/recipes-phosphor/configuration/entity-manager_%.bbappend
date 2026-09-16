FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://EVB-NUVOTON/Nuvoton-thermal.json \
    "

# for s997
SRC_URI:append:s997 = " file://EVB-NUVOTON/s997.json"

do_install:append () {
    install -m 0644 -D ${UNPACKDIR}/EVB-NUVOTON/Nuvoton-thermal.json ${D}/usr/share/entity-manager/configurations
}

# for s997
do_install:append:s997 () {
    install -m 0644 -D ${UNPACKDIR}/EVB-NUVOTON/s997.json ${D}/usr/share/entity-manager/configurations
}

