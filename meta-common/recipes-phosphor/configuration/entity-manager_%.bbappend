FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI:append = " \
    file://0001-Entity-manager-Add-support-to-update-assetTag.patch \
    file://solum_pssf162202_psu.json \
    file://cpld.json \
    file://eeprom.json \
    file://0007-Add-empty-EEPROM-Fru-Update-Support.patch \
    file://0008-Add-Configurable-FRU-ID-Support.patch \
    file://0004-Add-FruConfig-D-Bus-method.patch \
    "
SRCREV = "513976bed89432f4c24a40c7ba768f023dc280cd"
EXTRA_OEMESON:append = " -Dfru-device-resizefru=true"

do_install:append(){

     install -m 0444 ${WORKDIR}/cpld.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/eeprom.json ${D}/usr/share/entity-manager/configurations
}

