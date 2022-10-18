FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
	   file://0001-BMC-ARP-Control.patch \
           file://0002_readall_for_sensor_instanceStart.patch \
           file://0003-Add-system-Interface-Privilege-Confdition-Check.patch \
           file://0004-fix-systemInfo-parameter-response.patch \
           file://0005-VLAN-Priority.patch \
           file://0006-AutType-ErrorMsg.patch \
           file://0007-get-payload-access-fix.patch \
           file://0008-Enabled-SetSelTime-ipmi-Command.patch \
           file://0009-For-Get-set-user-payload-acess-created-users-will-ge.patch \
           file://0010-Add-warm-reset-support.patch \
           file://phosphor-ipmi-host-ami.service \
	   file://0011-Add-Compact-SDR-Type2-Support.patch \
           file://0012-Get-Channel-Payload-Support-Detailed-Information-bel.patch \
           "

do_install:append(){
  install -d ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/sensorhandler.hpp ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/selutility.hpp ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/phosphor-ipmi-warm-reset.target ${D}${systemd_system_unitdir}
  install -m 0644 -D ${WORKDIR}/phosphor-ipmi-host-ami.service ${D}${systemd_system_unitdir}/phosphor-ipmi-host.service
}

FILES:${PN} += "${systemd_system_unitdir}/*"

