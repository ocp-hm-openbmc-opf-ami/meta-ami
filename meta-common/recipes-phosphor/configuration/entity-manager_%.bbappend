FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI:append = " \
    file://solum_pssf162202_psu.json \
    file://cpld.json \
    "

do_install:append(){

     install -m 0444 ${WORKDIR}/cpld.json ${D}/usr/share/entity-manager/configurations
}

