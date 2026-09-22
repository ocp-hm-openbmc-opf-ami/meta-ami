FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"
SRC_URI:append = " file://imx95-chassis.json"

do_install:append() {
     rm -f ${D}/usr/share/entity-manager/configurations/*.json
     install -d ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/imx95-chassis.json ${D}/usr/share/entity-manager/configurations
}
