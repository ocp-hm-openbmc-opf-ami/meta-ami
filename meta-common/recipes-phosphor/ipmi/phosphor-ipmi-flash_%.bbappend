FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
PACKAGECONFIG:append = " ubitar-bmc static-bmc aspeed-lpc net-bridge reboot-update"

SRC_URI += " \
       file://config-static-bmc-reboot.json \
       file://config-tarball-bmc-reboot.json \
       file://phosphor-ipmi-flash-bmc-prepare.target \
       file://phosphor-ipmi-flash-bmc-update.target \
       file://phosphor-ipmi-flash-bmc-verify.target \
       "

do_install:append() {
  install -d ${D}${systemd_system_unitdir}
  install -m 0644 ${WORKDIR}/phosphor-ipmi-flash-bmc-prepare.target ${D}${systemd_system_unitdir}
  install -m 0644 ${WORKDIR}/phosphor-ipmi-flash-bmc-verify.target ${D}${systemd_system_unitdir}
  install -m 0644 ${WORKDIR}/phosphor-ipmi-flash-bmc-update.target ${D}${systemd_system_unitdir}

  install -d ${D}${datadir}/phosphor-ipmi-flash
  install -m 0644 ${WORKDIR}/config-static-bmc-reboot.json ${D}${datadir}/phosphor-ipmi-flash
  install -m 0644 ${WORKDIR}/config-tarball-bmc-reboot.json ${D}${datadir}/phosphor-ipmi-flash
}

