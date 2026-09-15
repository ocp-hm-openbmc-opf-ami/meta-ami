FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:devkit2700 = " file://power-config-devkit2700.json"

do_install:append:devkit2700() {
    install -m 0644 ${UNPACKDIR}/power-config-devkit2700.json \
        ${D}${datadir}/x86-power-control/power-config-host0.json
}