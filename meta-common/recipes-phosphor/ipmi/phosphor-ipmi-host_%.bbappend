FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://git@github.com/ocp-hm-openbmc-opf-ami/phosphor-host-ipmid;protocol=https;branch=master;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "ff1cc2ad4af41fca2f59b5b58f76e4c9fc6f2200"

RDEPENDS:${PN}:remove = "phosphor-time-manager"

SRC_URI += " \
           file://phosphor-ipmi-host-ami.service \
           file://phosphor-ipmi-host-evb-ami.service \
           file://0001-removing-sel-callbacks-update.patch \
           file://0002-Add-remote-mac-address.patch \
           "

SRC_URI_EGS:append = " \
    file://0001-Fix-for-sensorlist-timeout.patch"

DEPENDS += "libmapper"
do_install:append(){
  install -d ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/sensorhandler.hpp ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/selutility.hpp ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/phosphor-ipmi-warm-reset.target ${D}${systemd_system_unitdir}
  install -m 0644 -D ${WORKDIR}/phosphor-ipmi-host-ami.service ${D}${systemd_system_unitdir}/phosphor-ipmi-host.service
  if [ "${MACHINE}" = "evb-ast2600" ] || [ "${MACHINE}" = "evb-npcm845" ]; then
      install -m 0644 -D ${WORKDIR}/phosphor-ipmi-host-evb-ami.service ${D}${systemd_system_unitdir}/phosphor-ipmi-host.service
  fi

}

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'egs', SRC_URI_EGS, '', d)}"

FILES:${PN} += "${systemd_system_unitdir}/*"

