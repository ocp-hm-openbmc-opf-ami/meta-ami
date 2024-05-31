FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

#SRC_URI += " file://0002-Add-empty-EEPROM-Fru-Update-Support.patch "
SRC_URI:append = " \
    file://0001-Entity-manager-Add-support-to-update-assetTag.patch \
    file://solum_pssf162202_psu.json \
    file://cpld.json \
    file://eeprom.json \
    "
#SRCREV = "6fa0602db8250905808991e5f7206151dd28b346"
SRCREV = "513976bed89432f4c24a40c7ba768f023dc280cd"
EXTRA_OEMESON:append = " -Dfru-device-resizefru=true"

do_install:append(){

     install -m 0444 ${WORKDIR}/cpld.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/eeprom.json ${D}/usr/share/entity-manager/configurations
}

