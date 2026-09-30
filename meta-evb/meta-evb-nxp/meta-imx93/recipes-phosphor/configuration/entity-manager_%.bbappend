FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"
SRC_URI:append = " file://imx93-chassis.json"

do_install:append() {
     rm -f ${D}/usr/share/entity-manager/configurations/*.json
     install -d ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/imx93-chassis.json ${D}/usr/share/entity-manager/configurations
}