FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://power-config-host0.json \
                 "
# AST2700 A0 doesn't support SGPIO Slave interrupt.
# If the SGPIOS input pin is configured for x86-power-control PowerOk,
# the power status will not update.
# We use phosphor-inventory-manager to create DBus,
# We need to wait power-status-sync.service start running and update SGPIO value to DBus.
DEPS_CFG = "power.conf"
DEPS_TGT = "xyz.openbmc_project.Chassis.Control.Power@.service"
SYSTEMD_OVERRIDE:${PN}:append = "${DEPS_CFG}:${DEPS_TGT}.d/${DEPS_CFG}"


do_install:append() {
    install -d ${D}${datadir}/${PN}
    install -m 0644 ${WORKDIR}/power-config-host0.json ${D}${datadir}/${PN}
}
