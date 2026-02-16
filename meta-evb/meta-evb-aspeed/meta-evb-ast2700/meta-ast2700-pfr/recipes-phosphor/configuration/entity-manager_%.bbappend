FILESEXTRAPATHS:prepend:ast2700-dcscm-sdk-features := "${THISDIR}/${PN}:"

CONFIGFILE = "ast2700-dcscm.json"

SRC_URI:append:ast2700-dcscm-sdk-features = " file://${CONFIGFILE}"
SRC_URI:append:ast2700-dcscm-sdk-features = " file://blacklist.json"

do_install:append:ast2700-dcscm-sdk-features() {
     rm -f ${D}${datadir}/entity-manager/configurations/*.json
     install -d ${D}${datadir}/entity-manager/configurations
     install -m 0444 ${WORKDIR}/${CONFIGFILE} ${D}${datadir}/entity-manager/configurations
     install -m 0444 ${WORKDIR}/blacklist.json -D -t ${D}${datadir}/entity-manager
}
