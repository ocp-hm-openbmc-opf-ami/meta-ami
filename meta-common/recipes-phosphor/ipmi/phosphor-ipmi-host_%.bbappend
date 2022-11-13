FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "0a24e5cd3fb7f3f17e9c440fb8fb33bcffdfecfb"

SRC_URI += " \
	   file://0001-BMC-ARP-Control.patch \
           file://0002_readall_for_sensor_instanceStart.patch \
           file://0003-Add-system-Interface-Privilege-Confdition-Check.patch \
           file://0004-fix-systemInfo-parameter-response.patch \
           file://0005-VLAN-Priority.patch \
           file://0006-AutType-ErrorMsg.patch \
           file://0008-Enabled-SetSelTime-ipmi-Command.patch \
           file://0010-Add-warm-reset-support.patch \
           file://phosphor-ipmi-host-ami.service \
	   file://0011-Add-Compact-SDR-Type2-Support.patch \
           file://0012-Get-Channel-Payload-Support-Detailed-Information-bel.patch \
	   file://0037-Systemd_Restart_Wrappper.patch \
           file://dcmi-getActive-command.patch \
           file://0013-Enable-Ipv6-static-address-and-disable-ipv6-dynamic-address.patch \  
           file://dcmi_getDCMICapabilities_info_oldHandler_to_newHandler.patch \ 
	   file://dcmi_old_to_new_handler_implementation.patch \
           "

do_install:append(){
  install -d ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/sensorhandler.hpp ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/selutility.hpp ${D}${includedir}/phosphor-ipmi-host
  install -m 0644 -D ${S}/phosphor-ipmi-warm-reset.target ${D}${systemd_system_unitdir}
  install -m 0644 -D ${WORKDIR}/phosphor-ipmi-host-ami.service ${D}${systemd_system_unitdir}/phosphor-ipmi-host.service
}

FILES:${PN} += "${systemd_system_unitdir}/*"

