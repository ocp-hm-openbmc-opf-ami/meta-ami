FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"
#AMI-AC-Baseboard.json  and AMI-solum_pssf162202_psu.json is the local AC-Baseboard.json which will contain the Changes from AMI.
#AMI-AC-Baseboard.json and AMI-solum_pssf162202_psu.json will replace the Default AC-Baseboard.json and solum_pssf162202_psu.json in rootfs
SRC_URI:append = " \
    file://AMI-AC-Baseboard.json \
    file://AMI-solum_pssf162202_psu.json \
    "

do_install:append(){
         install -d ${D}/usr/share/entity-manager/configurations
         install -m 0444 ${WORKDIR}/AMI-AC-Baseboard.json ${D}/usr/share/entity-manager/configurations/AC-Baseboard.json
         install -m 0444 ${WORKDIR}/AMI-solum_pssf162202_psu.json ${D}/usr/share/entity-manager/configurations/solum_pssf162202_psu.json
}

