FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-host-ipmid.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "0d513ad99ca8105830a79d005e58ea4bc0db7fa7"

SRC_URI += " \
           file://phosphor-ipmi-host-ami.service \
           file://phosphor-ipmi-host-evb-ami.service \
           "

SRC_URI_EGS:append = " \
    file://0001-Fix-for-sensorlist-timeout.patch"

do_install:append(){
  install -d ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/sensorhandler.hpp ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/selutility.hpp ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/phosphor-ipmi-warm-reset.target ${D}${systemd_system_unitdir}
  install -m 0644 -D ${WORKDIR}/phosphor-ipmi-host-ami.service ${D}${systemd_system_unitdir}/phosphor-ipmi-host.service
  if [ "${MACHINE}" = "evb-ast2600" ]; then
      install -m 0644 -D ${WORKDIR}/phosphor-ipmi-host-evb-ami.service ${D}${systemd_system_unitdir}/phosphor-ipmi-host.service
  fi

}

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'egs', SRC_URI_EGS, '', d)}"

FILES:${PN} += "${systemd_system_unitdir}/*"

