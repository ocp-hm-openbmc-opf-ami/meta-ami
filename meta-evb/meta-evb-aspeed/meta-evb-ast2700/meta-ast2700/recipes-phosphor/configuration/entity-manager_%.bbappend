FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI:append = " \
                   file://ast2700-evb.json \
                   file://blacklist.json \
                 "

do_install:append() {
     rm -f ${D}${datadir}/entity-manager/configurations/*.json
     install -d ${D}${datadir}/entity-manager/configurations
     install -m 0444 ${WORKDIR}/ast2700-evb.json ${D}${datadir}/entity-manager/configurations
     install -m 0444 ${WORKDIR}/blacklist.json -D -t ${D}${datadir}/entity-manager
}

