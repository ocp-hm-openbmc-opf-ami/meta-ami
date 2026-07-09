FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/phosphor-host-ipmid.git;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "7e40561d8cdc01e11857533b488df7804564175c"

RDEPENDS:${PN}:remove = "phosphor-time-manager"
DEPENDS:append = " libpdkhook "
RDEPENDS:${PN}:append = " libpdkhook "

SRC_URI += " \
           file://phosphor-ipmi-host-ami.service \
           file://phosphor-ipmi-host-evb-ami.service \
           "

SRC_URI_EGS:append = " \
    file://0001-Fix-for-sensorlist-timeout.patch"

DEPENDS += "libmapper"
do_install:append(){
  install -d ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/sensorhandler.hpp ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/selutility.hpp ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/phosphor-ipmi-warm-reset.target ${D}${systemd_system_unitdir}
  install -m 0644 -D ${UNPACKDIR}/phosphor-ipmi-host-ami.service ${D}${systemd_system_unitdir}/phosphor-ipmi-host.service
  if [ "${MACHINE}" = "evb-ast2600" ] || [ "${MACHINE}" = "evb-npcm845" ]; then
      install -m 0644 -D ${UNPACKDIR}/phosphor-ipmi-host-evb-ami.service ${D}${systemd_system_unitdir}/phosphor-ipmi-host.service
  fi

}

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'egs', SRC_URI_EGS, '', d)}"

FILES:${PN} += "${systemd_system_unitdir}/*"

