FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://bmc_health_config.json \
                   file://memorycritical.service \
                   file://memorycritical.target \
                   file://memorycritical.sh \
                   file://memorywarning.service \
                   file://memorywarning.target \
                   file://memorywarning.sh \
                 "


do_install:append() {
   install -d ${D}${bindir}
   install -m 0755 ${WORKDIR}/memorycritical.sh ${D}${bindir}/memorycritical.sh
   install -m 0755 ${WORKDIR}/memorywarning.sh ${D}${bindir}/memorywarning.sh

   # Install configuration file
   install -d ${D}${sysconfdir}/healthMon
   install -m 0644 ${WORKDIR}/bmc_health_config.json ${D}${sysconfdir}/healthMon

   # Install systemd service and target files
   install -d ${D}${systemd_system_unitdir}
   install -m 0644 ${WORKDIR}/memorycritical.service ${D}${systemd_system_unitdir}/memorycritical.service
   install -m 0644 ${WORKDIR}/memorycritical.target ${D}${systemd_system_unitdir}/memorycritical.target
   install -m 0644 ${WORKDIR}/memorywarning.service ${D}${systemd_system_unitdir}/memorywarning.service
   install -m 0644 ${WORKDIR}/memorywarning.target ${D}${systemd_system_unitdir}/memorywarning.target
   
}

SYSTEMD_SERVICE:${PN} += "memorycritical.target" 
SYSTEMD_SERVICE:${PN} += "memorycritical.service"
SYSTEMD_SERVICE:${PN} += "memorywarning.target" 
SYSTEMD_SERVICE:${PN} += "memorywarning.service"


