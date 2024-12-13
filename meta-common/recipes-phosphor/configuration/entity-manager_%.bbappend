FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI:append = " \
    file://solum_pssf162202_psu.json \
    file://cpld.json \
    file://eeprom.json \
    file://preserve_configuration.json \
    file://preserve_network_configuration.json \
    file://0001-Entity-manager-Add-support-to-update-assetTag.patch \
    file://0002-Add-Config-FRU-Support.patch \
    file://0003-add-new-interface-for-partial-preserve-config-suppor.patch \
    file://0004-Added-Fix-For-SDR-Preserve-Configuration.patch \
    "
SRCREV = "e2c84df172af7d5a7434b67bd37db89fc6c1b939"

EXTRA_OEMESON:append = " -Dfru-device-resizefru=true"

do_install:append(){

     install -m 0444 ${WORKDIR}/cpld.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/eeprom.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/preserve_configuration.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/preserve_network_configuration.json ${D}/usr/share/entity-manager/configurations
}

