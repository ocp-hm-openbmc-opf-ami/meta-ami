FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-health-monitor.git;branch=integrate-onetree-3.1.1;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "f529cf89154a9f5700468c49953de40036f73105"

SRC_URI:append = " file://bmc_health_config.json \
                   file://memorycritical.service \
                   file://memorycritical.target \
                   file://memorycritical.sh \
                 "


do_install:append() {
   install -d ${D}${bindir}
   install -m 0755 ${UNPACKDIR}/memorycritical.sh ${D}${bindir}/memorycritical.sh

   # Install configuration file
   install -d ${D}${sysconfdir}/healthMon
   install -m 0644 ${UNPACKDIR}/bmc_health_config.json ${D}${sysconfdir}/healthMon

   # Install systemd service and target files
   install -d ${D}${systemd_system_unitdir}
   install -m 0644 ${UNPACKDIR}/memorycritical.service ${D}${systemd_system_unitdir}/memorycritical.service
   install -m 0644 ${UNPACKDIR}/memorycritical.target ${D}${systemd_system_unitdir}/memorycritical.target
   
}

SYSTEMD_SERVICE:${PN} += "memorycritical.target" 
SYSTEMD_SERVICE:${PN} += "memorycritical.service"


