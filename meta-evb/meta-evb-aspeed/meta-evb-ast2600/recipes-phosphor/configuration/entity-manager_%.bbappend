FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://EVB-2600/ast2600-evb.json \
    "

do_install:append(){

     # Remove unnecessary config files. EntityManager spends significant time parsing these.
    rm -rf ${D}/usr/share/entity-manager/configurations/*
    install -m 0444 ${UNPACKDIR}/EVB-2600/ast2600-evb.json ${D}/usr/share/entity-manager/configurations

}

