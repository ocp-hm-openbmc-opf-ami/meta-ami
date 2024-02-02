FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"

SRC_URI:append = " \
    file://solum_pssf162202_psu.json \
    file://cpld.json \
    "
SRCREV = "6fa0602db8250905808991e5f7206151dd28b346"

do_install:append(){

     install -m 0444 ${WORKDIR}/cpld.json ${D}/usr/share/entity-manager/configurations
}

