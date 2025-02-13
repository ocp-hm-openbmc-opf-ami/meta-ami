FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://Nuvoton-thermal.json \
    "

do_install:append () {
    install -m 0644 -D ${WORKDIR}/Nuvoton-thermal.json ${D}/usr/share/entity-manager/configurations
}

