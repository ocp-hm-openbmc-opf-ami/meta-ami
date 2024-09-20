FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI:append = " \
    file://solum_pssf162202_psu.json \
    file://cpld.json \
    file://eeprom.json \
    file://0001-Entity-manager-Add-support-to-update-assetTag.patch \
    file://0002-Add-Config-FRU-Support.patch \
    "
SRCREV = "e2c84df172af7d5a7434b67bd37db89fc6c1b939"

EXTRA_OEMESON:append = " -Dfru-device-resizefru=true"

do_install:append(){

     install -m 0444 ${WORKDIR}/cpld.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/eeprom.json ${D}/usr/share/entity-manager/configurations
}

