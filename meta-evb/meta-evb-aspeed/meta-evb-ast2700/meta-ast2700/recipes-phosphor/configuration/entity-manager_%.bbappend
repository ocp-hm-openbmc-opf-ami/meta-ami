FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
                   file://EVB-2700/ast2700-evb.json \
                   file://blacklist.json \
                 "

do_install:append() {
     rm -f ${D}${datadir}/entity-manager/configurations/*.json
     install -d ${D}${datadir}/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/EVB-2700/ast2700-evb.json ${D}${datadir}/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/blacklist.json -D -t ${D}${datadir}/entity-manager
}

# Add nostamp to avoid build failure when the machine changes.
do_configure[nostamp] = "1"
do_compile[nostamp] = "1"
do_install[nostamp] = "1"

