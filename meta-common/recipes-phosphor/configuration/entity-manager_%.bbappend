FILESEXTRAPATHS:append := ":${THISDIR}/${PN}"
#AMI-AC-Baseboard.json is the local AC-Baseboard.json which will contain the Changes from AMI.
#AMI-AC-Baseboard.json will replace the Default AC-Baseboard.json in rootfs
SRC_URI:append = " \
    file://AMI-AC-Baseboard.json \
    "

do_install:append(){
     install -d ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/AMI-AC-Baseboard.json ${D}/usr/share/entity-manager/configurations/AC-Baseboard.json
}

