FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

CONFIGFILE = "power-config-host0.json"

SRC_URI:append:ast2700-dcscm-sdk-features = " file://${CONFIGFILE}"

do_install:append:ast2700-dcscm-sdk-features() {
    install -d ${D}${datadir}/${PN}
    install -m 0644 ${UNPACKDIR}/${CONFIGFILE} ${D}${datadir}/${PN}/power-config-host0.json
}
