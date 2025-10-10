FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://bmc_health_config.json \
                   file://memorycritical.service \
                   file://memorycritical.target \
                   file://memorycritical.sh \
                 "


do_install:append() {
   install -d ${D}${bindir}
   install -m 0755 ${WORKDIR}/memorycritical.sh ${D}${bindir}/memorycritical.sh

   # Install configuration file
   install -d ${D}${sysconfdir}/healthMon
   install -m 0644 ${WORKDIR}/bmc_health_config.json ${D}${sysconfdir}/healthMon

   # Install systemd service and target files
   install -d ${D}${systemd_system_unitdir}
   install -m 0644 ${WORKDIR}/memorycritical.service ${D}${systemd_system_unitdir}/memorycritical.service
   install -m 0644 ${WORKDIR}/memorycritical.target ${D}${systemd_system_unitdir}/memorycritical.target
   
}

SYSTEMD_SERVICE:${PN} += "memorycritical.target" 
SYSTEMD_SERVICE:${PN} += "memorycritical.service"


