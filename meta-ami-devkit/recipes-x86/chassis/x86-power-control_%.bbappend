FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://power-config-host0.json"

# DevKit wires only the power/reset/post signals; SIO and NMI lines are absent.
do_install:append() {
    install -d ${D}${datadir}/${PN}
    install -m 0644 ${UNPACKDIR}/power-config-host0.json ${D}${datadir}/${PN}/
}
