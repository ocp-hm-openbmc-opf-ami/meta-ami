SYSTEMD_SERVICE:${PN}-chassis:remove = "phosphor-reset-chassis-on@.service phosphor-reset-chassis-running@.service"

SRC_URI:remove = "file://0001-Timer-Support-for-manager-reset-operation.patch"

do_install:append() {
    rm -f ${D}${systemd_unitdir}/system/phosphor-reset-chassis-on@.service
    rm -f ${D}${systemd_unitdir}/system/phosphor-reset-chassis-running@.service
}
