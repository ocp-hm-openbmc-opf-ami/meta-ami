SUMMARY = "AMI OneTree Features and Extension packages"

inherit packagegroup
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${AMIBASE}/COPYING.AMI;md5=65a69a674f34a9f30737c9f0abd4fc5c"

PROVIDES = "${PACKAGES}"
PACKAGES = "\
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-brcmraid', '${PN}-brcmraid', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-nic', '${PN}-nic', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-nvme', '${PN}-nvme', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-nvmebasic', '${PN}-nvmebasic', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-fwupdate', '${PN}-fwupdate', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-brcmpciesw', '${PN}-brcmpciesw', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-rtp', '${PN}-rtp', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-msccraid', '${PN}-msccraid', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-intel-pfr', '${PN}-intel-pfr', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-gpgpu', '${PN}-gpgpu', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-acd', '${PN}-acd', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-asd', '${PN}-asd', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-mrt', '${PN}-mrt', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-amdremotedbg', '${PN}-amdremotedbg', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-intelsipack', '${PN}-intelsipack', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-kvm', '${PN}-kvm', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-media-redirect', '${PN}-media-redirect', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-jviewer', '${PN}-jviewer', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-webui', '${PN}-webui', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-amd-apml', '${PN}-amd-apml', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-amd-addc', '${PN}-amd-addc', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-amd-powercap', '${PN}-amd-powercap', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-amd-lcd', '${PN}-amd-lcd', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-sensors', '${PN}-sensors', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-power', '${PN}-power', '', d)} \
        ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-phosphor-power', '${PN}-phosphor-power', '', d)} \
        ${@bb.utils.contains('IMAGE_FEATURES', 'onetree-gpio-presence', '${PN}-gpio-presence', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-fru', '${PN}-fru', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-sel', '${PN}-sel', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-postcode', '${PN}-postcode', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-pef-alert', '${PN}-pef-alert', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-snmp', '${PN}-snmp', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-smtp', '${PN}-smtp', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-sol', '${PN}-sol', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-session', '${PN}-session', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-radius-client', '${PN}-radius-client', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-license', '${PN}-license', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-backup-restore', '${PN}-backup-restore', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-host-error', '${PN}-host-error', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-thermal-mgnt', '${PN}-thermal-mgnt', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-ntp', '${PN}-ntp', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-slpd', '${PN}-slpd', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-lldpd', '${PN}-lldpd', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-bootlogo', '${PN}-bootlogo', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-2fa', '${PN}-2fa', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-prov-mode-mgr', '${PN}-prov-mode-mgr', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-rbc-mgr', '${PN}-rbc-mgr', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-ipmi-blobs', '${PN}-ipmi-blobs', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-biosconfig-manager', '${PN}-biosconfig-manager', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-spdm', '${PN}-spdm', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-intel-pldm', '${PN}-intel-pldm', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-intel-mctp', '${PN}-intel-mctp', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-network', '${PN}-network', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-network-system-firewall-support', '${PN}-network-system-firewall-support', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-network-advanced-route-support', '${PN}-network-advanced-route-support', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-network-bonding-support', '${PN}-network-bonding-support', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-network-openssl-support', '${PN}-network-openssl-support', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-network-disable-ping-support', '${PN}-network-disable-ping-support', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-network-iperf3-support', '${PN}-network-iperf3-support', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-network-ncsi-support', '${PN}-network-ncsi-support', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-fwupdate-cpld-update', '${PN}-fwupdate-cpld-update', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-image-sign', '${PN}-image-sign', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-dual-image', '${PN}-dual-image', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-hw-failsafe-boot', '${PN}-hw-failsafe-boot', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-single-spi-abr', '${PN}-single-spi-abr', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-sync-conf', '${PN}-sync-conf', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-ipmi-ssif', '${PN}-ipmi-ssif', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-nvidiasipack', '${PN}-nvidiasipack', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-tools', '${PN}-tools', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-host-interface', '${PN}-host-interface', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-extlog', '${PN}-extlog', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-network-phy-configuration-support', '${PN}-network-phy-configuration-support', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-network-nsupdate-support', '${PN}-network-nsupdate-support', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-network-tsig-support', '${PN}-network-tsig-support', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-network-persist-mac-support', '${PN}-network-persist-mac-support', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-network-avahi-support', '${PN}-network-avahi-support', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-phosphor-ipmi-flash', '${PN}-phosphor-ipmi-flash', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-mctp-i3c-sock', '${PN}-mctp-i3c-sock', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-pldm', '${PN}-pldm', '', d)} \
		${@bb.utils.contains('IMAGE_FEATURES', 'onetree-bmc-services-ready', '${PN}-bmc-services-ready', '', d)} \
		"


SUMMARY:${PN}-mctp-i3c-sock = "MCTP I3C Socket Application Daemon"
DESCRIPTION:${PN}-mctp-i3c-sock = "Implemented a socket-based MCTP over I3C application independent of libmctp, using the Linux MCTP socket (AF_MCTP) and MCTP I3C transport drivers. The application establishes connections based on Endpoint ID (EID) and message type, following the MCTP over I3C (DSP0233) specification."
RDEPENDS:${PN}-mctp-i3c-sock = " mctp-i3c-app"
SUPPORTED_VENDOR:${PN}-mctp-i3c-sock = "INTEL"
#-----------------------------------#


SUMMARY:${PN}-brcmraid = "EP : Broadcom RAID"
DESCRIPTION:${PN}-brcmraid = "Service that manage Broadcom Storelib7 RAID/HBA controllers"
RDEPENDS:${PN}-brcmraid = " raid-mgmt \
			    raid-brcm \
			    hba-mgmt \
			    hba-brcm \
			"
SUPPORTED_VENDOR:${PN}-brcmraid = "ALL"
#-----------------------------------#

SUMMARY:${PN}-nic = "EP : NIC"
DESCRIPTION:${PN}-nic = "Manage the Network Interface Controller by way of MCTP over SMBus and MCTP over PCIe "
RDEPENDS:${PN}-nic = "	nic \
			nic-mgmt \
		    "
SUPPORTED_VENDOR:${PN}-nic = "ALL"
#-----------------------------------#

SUMMARY:${PN}-nvme = "EP : NVME"
DESCRIPTION:${PN}-nvme = "Enables host software to communicate with a non-volatile memory subsystem over PCI Express "
RDEPENDS:${PN}-nvme = " nvme \
			nvme-mgmt \
		     "
SUPPORTED_VENDOR:${PN}-nvme = "ALL"
#-----------------------------------#

SUMMARY:${PN}-nvmebasic = "EP : NVME BASIC"
DESCRIPTION:${PN}-nvmebasic = ""
RDEPENDS:${PN}-nvmebasic = " nvme-basic \
			     nvmebasic-mgmt \
			"
SUPPORTED_VENDOR:${PN}-nvmebasic = "ALL"
#-----------------------------------#

SUMMARY:${PN}-fwupdate = "EP : Firmware Update"
DESCRIPTION:${PN}-fwupdate = "Supports in creating inventory and allow updating CPLD devices \
			      through multiple interfaces "
RDEPENDS:${PN}-fwupdate = " \
			    cpld-tool \
			"
SUPPORTED_VENDOR:${PN}-fwupdate = "ALL"
#-----------------------------------#

SUMMARY:${PN}-fwupdate-cpld-update = " CPLD Update"
DESCRIPTION:${PN}-fwupdate-cpld-update = "Supports to update Firmware for CPLD "
RDEPENDS:${PN}-fwupdate-cpld-update = " \
			"
SUPPORTED_VENDOR:${PN}-fwupdate-cpld-update = "ALL"
#-----------------------------------#

SUMMARY:${PN}-brcmpciesw = "EP : Broadcom PCIe Switch"
DESCRIPTION:${PN}-brcmpciesw = "Enables PEX89000 switch, which provides a versatile platform for constructing \
				systems that range from basic PCIe connections within a device "
RDEPENDS:${PN}-brcmpciesw = "i2c-pciesw \
				libscrutiny \
				mctp-pciesw \
				pciesw-service \
				scrutiny-ifc\
			   "
SUPPORTED_VENDOR:${PN}-brcmpciesw = "ALL"
#-----------------------------------#

SUMMARY:${PN}-intel-pfr = "Intel Platform Firmware Resilience (PFR)"
DESCRIPTION:${PN}-intel-pfr = "Monitor and validate firmware integrity using an Intel FPGA"
RDEPENDS:${PN}-intel-pfr = ""
SUPPORTED_VENDOR:${PN}-intel-pfr = "INTEL"
#-----------------------------------#

SUMMARY:${PN}-rtp = "EP : Redfish"
DESCRIPTION:${PN}-rtp = "AMI Redfish Extension Packs"
RDEPENDS:${PN}-rtp = "  \	
		    "
SUPPORTED_VENDOR:${PN}-rtp = "ALL"
#-----------------------------------#

SUMMARY:${PN}-msccraid = "EP : Microchip RAID"
DESCRIPTION:${PN}-msccraid = "Service that manage Microchip RAID controllers"
RDEPENDS:${PN}-msccraid = " storage-mgmt \
			    raid-mscc\
			"
SUPPORTED_VENDOR:${PN}-msccraid = "ALL"
#-----------------------------------#

SUMMARY:${PN}-gpgpu = "EP : GPGPU"
DESCRIPTION:${PN}-gpgpu = "Manages the set of server components through SMBUS Post Box over \
			   I2C/PCIe interface, designed to leverage GPGPU capabilities "
RDEPENDS:${PN}-gpgpu = " onetree-gpgpu \
	            "
SUPPORTED_VENDOR:${PN}-gpgpu = "NVIDIA"
#-----------------------------------#

SUMMARY:${PN}-acd = "EP : ACD Autonomously dump system data when crashing"
DESCRIPTION:${PN}-acd = "Provides debug logs from the host system via the BMC in the event of a crash dump"
RDEPENDS:${PN}-acd = "  crashdump \
			aic-crashdump \
			ami-acd-dbus \
			bafi-dev \
		        "
SUPPORTED_VENDOR:${PN}-acd = "INTEL"
#-----------------------------------#

SUMMARY:${PN}-asd = "EP : ASD package contains the JTAG Transport"
DESCRIPTION:${PN}-asd = "The Intel At-Scale Debug tool allows to use any host system to run the Debug tool stack while connecting to the target system across the network "
RDEPENDS:${PN}-asd = " at-scale-debug \
		       ami-asd-dbus \
		   "
SUPPORTED_VENDOR:${PN}-asd = "INTEL"
#-----------------------------------#

SUMMARY:${PN}-mrt = "EP : Intel Memory Resilience Technology"
DESCRIPTION:${PN}-mrt = ""
RDEPENDS:${PN}-mrt = " memory-error-collector  \
                       memory-resilience-technology-engine  \
		   "
SUPPORTED_VENDOR:${PN}-mrt = "INTEL"
#-----------------------------------#

SUMMARY:${PN}-amdremotedbg = "EP : AMDRemoteDebug"
DESCRIPTION:${PN}-amdremotedbg = " Remote debugging tools for AMD based platforms"
RDEPENDS:${PN}-amdremotedbg = "  amd-remote-debug \
				 amd-redebug-dbus \
				 "
SUPPORTED_VENDOR:${PN}-amdremotedbg = "AMD"
#-----------------------------------#

SUMMARY:${PN}-intelsipack = "EP : Intel Silicon Technology Expansion Package"
DESCRIPTION:${PN}-intelsipack = "This EP includes a set of Intel silicon-specific features,  such as RAS (Reliability, Availability, and Serviceability) offload, Platform Monitoring Technology (PMT),  Node Manager (NM) , and Compute Usage Per Second  (CUPS) "
RDEPENDS:${PN}-intelsipack = " "
SUPPORTED_VENDOR:${PN}-intelsipack = "INTEL"
#-----------------------------------#

SUMMARY:${PN}-intel-pldm = "Intel PLDM stack"
DESCRIPTION:${PN}-intel-pldm = "Implementation of the PLDM specifications"
RDEPENDS:${PN}-intel-pldm = " pldmd"
SUPPORTED_VENDOR:${PN}-intel-pldm = "INTEL"
#-----------------------------------#

SUMMARY:${PN}-intel-mctp = "Intel MCTP stack"
DESCRIPTION:${PN}-intel-mctp = "Implementation of the MCTP specifications"
RDEPENDS:${PN}-intel-mctp = " pmci-launcher mctpd"
SUPPORTED_VENDOR:${PN}-intel-mctp = "INTEL"
#-----------------------------------#

SUMMARY:${PN}-kvm = "AMI Core Features: KVM Support"
DESCRIPTION:${PN}-kvm = " Provide remote video support. Includes obmc-ikvm video server which serves video for KVM clients." 
RDEPENDS:${PN}-kvm = " obmc-ikvm \
		       kvm-dbus-monitor " 
SUPPORTED_VENDOR:${PN}-kvm = "ALL"
#-----------------------------------#

SUMMARY:${PN}-media-redirect = "AMI Core Features: Media Support"
DESCRIPTION:${PN}-media-redirect = " Provide remote media redirection. Includes virtual-media server which serves media for Media clients." 
RDEPENDS:${PN}-media-redirect = " virtual-media "
SUPPORTED_VENDOR:${PN}-media-redirect = "ALL"
#-----------------------------------#

SUMMARY:${PN}-jviewer = "AMI Core Features: JViewer Support"
DESCRIPTION:${PN}-jviewer = " Provide JViewer KVM client support. Includes Java Based KVM Client used for KVM redirection."
RDEPENDS:${PN}-jviewer = " jviewer "
SUPPORTED_VENDOR:${PN}-jviewer = "ALL"
#-----------------------------------#

SUMMARY:${PN}-webui = "AMI Core Features: Web UI support"
DESCRIPTION:${PN}-webui = "This is mandatory feature and by default always should be enabled for Web UI support.   This feature tightly coupled with obmc-bmcweb server."
RDEPENDS:${PN}-webui = " webui-vue "
SUPPORTED_VENDOR:${PN}-webui = "ALL"
#-----------------------------------#

SUMMARY:${PN}-amd-apml = "EP : AMD APML "
DESCRIPTION:${PN}-amd-apml = "Provide a user space interface to monitor and control the CPU's Systems Management features"
RDEPENDS:${PN}-amd-apml = "amd-apml"
SUPPORTED_VENDOR:${PN}-amd-apml = "AMD"
#-----------------------------------#

SUMMARY:${PN}-amd-addc = "EP : AMD ADDC"
DESCRIPTION:${PN}-amd-addc = "Harvest host failure information with minimal human intervention"
RDEPENDS:${PN}-amd-addc = "amd-apml \
			   amd-addc "
SUPPORTED_VENDOR:${PN}-amd-addc = "AMD"
#-----------------------------------#

SUMMARY:${PN}-amd-powercap = "EP : AMD Power Cap"
DESCRIPTION:${PN}-amd-powercap = "Provide system power information and help to manage and stable the energy consumption"
RDEPENDS:${PN}-amd-powercap = "amd-power-capping"
SUPPORTED_VENDOR:${PN}-amd-powercap = "AMD"
#-----------------------------------#

SUMMARY:${PN}-amd-lcd = "EP : AMD LCD"
DESCRIPTION:${PN}-amd-lcd = "Provide methods to control LCD screen on AMD platform"
RDEPENDS:${PN}-amd-lcd = " amd-lcd-lib"
SUPPORTED_VENDOR:${PN}-amd-lcd = "AMD"
#-----------------------------------#

#Below are the AMI Core features packagegroup
SUMMARY:${PN}-sensors = "AMI Core Features: Sensor Monitoring"
DESCRIPTION:${PN}-sensors = " Collection of sensor applications that provides \
				diffrent type of sensors such as: ADC, PSU, Power,\
				 NVME, Watchdog etc..."
RDEPENDS:${PN}-sensors = " dbus-sensors sensor-reader emmc-enable "
SUPPORTED_VENDOR:${PN}-sensors = "ALL"
#-----------------------------------#

SUMMARY:${PN}-power = "AMI Core Features: Power Control"
DESCRIPTION:${PN}-power = " Manages system power control, including various \
				power operations such as power-on, power-off, \
				power cycle, reset, and status monitoring."
RDEPENDS:${PN}-power = " x86-power-control"
SUPPORTED_VENDOR:${PN}-power = "ALL"
#-----------------------------------#

SUMMARY:${PN}-phosphor-power = "AMI Core Features: Phosphor Power"
DESCRIPTION:${PN}-phosphor-power = " Configuring and monitoring power-delivery devices \
                it includes actively maintained tools like cold-redundency, \
                phosphor-power-sequencer, and phosphor-regulators."
RDEPENDS:${PN}-phosphor-power = " phosphor-power"
SUPPORTED_VENDOR:${PN}-phosphor-power = "ALL"
#-----------------------------------#

SUMMARY:${PN}-gpio-presence = "AMI Core Features: GPIO Presence"
DESCRIPTION:${PN}-gpio-presence = " Managing GPIO  presence detection \
                it will create an object for the GPIO presence and \
                displays the GPIO pin value as property in the D-Bus."
RDEPENDS:${PN}-gpio-presence = " gpio-presence"
SUPPORTED_VENDOR:${PN}-gpio-presence = "ALL"
#-----------------------------------#

SUMMARY:${PN}-fru = "AMI Core Features: Field Replacable Unit, Inventory Management"
DESCRIPTION:${PN}-fru = " Provide a D-Bus inventory for configured \
				data and also scan all available IPMI FRU."
RDEPENDS:${PN}-fru = " entity-manager \
            fru-device \
			default-fru "
SUPPORTED_VENDOR:${PN}-fru = "ALL"
#-----------------------------------#

SUMMARY:${PN}-sel = "AMI Core Features: System Event Logs"
DESCRIPTION:${PN}-sel = " Records and manages system events, providing \
			  logs for debugging and monitoring hardware issues"
RDEPENDS:${PN}-sel = " phosphor-sel-logger"
SUPPORTED_VENDOR:${PN}-sel = "ALL"
#-----------------------------------#

SUMMARY:${PN}-postcode = "AMI Core Features: Post Code Manager"
DESCRIPTION:${PN}-postcode = " Provides infrastructure to persist the POST codes \
				in the BMC filesystem and exposes the BIOS POST \
				codes to the D-Bus"
RDEPENDS:${PN}-postcode = " phosphor-host-postd \
			    phosphor-post-code-manager "
SUPPORTED_VENDOR:${PN}-postcode = "ALL"
#-----------------------------------#

SUMMARY:${PN}-pef-alert = "AMI Core Features: Platform Event Filtering and Alert manager"
DESCRIPTION:${PN}-pef-alert = " Monitors system events and triggers alerts to enhance system \
				management and security"
RDEPENDS:${PN}-pef-alert = " pef-alert-manager"
SUPPORTED_VENDOR:${PN}-pef-alert = "ALL"
#-----------------------------------#

SUMMARY:${PN}-snmp = "AMI Core Features: Simple Network Management Protocol"
DESCRIPTION:${PN}-snmp = " SNMP used to get and modify the  system information \
			   also provides trap functionality"
RDEPENDS:${PN}-snmp = " net-snmp \
			net-snmp-server \
			net-snmp-mibs \
			net-snmp-client \
			snmp-agent \
			phosphor-snmp "
SUPPORTED_VENDOR:${PN}-snmp = "ALL"
#-----------------------------------#

SUMMARY:${PN}-smtp = "AMI Core Features: Simple Mail Transfer Protocol"
DESCRIPTION:${PN}-smtp = " SMTP is a communication protocol used for sending \
				and relaying email messages between servers \
				over the internet."
RDEPENDS:${PN}-smtp = "mail-alert-manager"
SUPPORTED_VENDOR:${PN}-smtp = "ALL"
#-----------------------------------#

SUMMARY:${PN}-sol = "AMI Core Features: Serial Over Lan"
DESCRIPTION:${PN}-sol = " Serial Over LAN (SOL) used for the redirection of baseboard \
                          serial controller traffic over an SSH or IPMI session."
RDEPENDS:${PN}-sol = " obmc-console phosphor-hostlogger"
SUPPORTED_VENDOR:${PN}-sol = "ALL"
#-----------------------------------#

SUMMARY:${PN}-session = "AMI Core Features: Session Manager"
DESCRIPTION:${PN}-session = " Session Management library contains dbus methods \
				and properties for storing the session information"
RDEPENDS:${PN}-session = " session-management"
SUPPORTED_VENDOR:${PN}-session = "ALL"
#-----------------------------------#

SUMMARY:${PN}-radius-client = "AMI Core Features: Radius Client"
DESCRIPTION:${PN}-radius-client = " Firmware to initiate client connection  to server for \
					validating user name and password which was stored \
					in RADIUS server"
RDEPENDS:${PN}-radius-client = " radiusclient-ng \
				nss-pam-radiusd "
SUPPORTED_VENDOR:${PN}-radius-client = "ALL"
#-----------------------------------#

SUMMARY:${PN}-license = "AMI Core Features: License control"
DESCRIPTION:${PN}-license = " The License Control overseeing licensable services, \
                              enforcing license validity, and facilitating key \
                              management service."
RDEPENDS:${PN}-license = " license-control"
SUPPORTED_VENDOR:${PN}-license = "ALL"
#-----------------------------------#

SUMMARY:${PN}-backup-restore = "AMI Core Features: Backup/Restore BMC configurations"
DESCRIPTION:${PN}-backup-restore = " Backup-Restore BMC Configurations Support provides \
                                     way to backup running BMC configuration and to apply \
                                     the BMC configuration to multiple running BMC's."
RDEPENDS:${PN}-backup-restore = " backuprestore"
SUPPORTED_VENDOR:${PN}-backup-restore = "ALL"
#-----------------------------------#

SUMMARY:${PN}-host-error = "AMI Core Features:"
DESCRIPTION:${PN}-host-error = ""
RDEPENDS:${PN}-host-error = " host-error-monitor"
SUPPORTED_VENDOR:${PN}-host-error = "ALL"
#-----------------------------------#

SUMMARY:${PN}-thermal-mgnt = "AMI Core Features: Thermal Management"
DESCRIPTION:${PN}-thermal-mgnt = " Used to monitor and regulate the temperature of components"
RDEPENDS:${PN}-thermal-mgnt = " phosphor-pid-control"
SUPPORTED_VENDOR:${PN}-thermal-mgnt = "ALL"
#-----------------------------------#

SUMMARY:${PN}-ntp = "AMI Core Features: Network Time Manager"
DESCRIPTION:${PN}-ntp = " Synchronizes the system time with remote time \
				servers to ensure accurate timekeeping"
RDEPENDS:${PN}-ntp = " phosphor-time-manager \
		       tzdata "
SUPPORTED_VENDOR:${PN}-ntp = "ALL"
#-----------------------------------#

SUMMARY:${PN}-slpd = "AMI Core Features: Service Location Protocol support"
DESCRIPTION:${PN}-slpd = " The Service Location Protocol provides a scalable framework for \
                           the discovery and selection of network services.  Using this \
                           protocol, computers using the Internet need little or no static \
                           configuration of network services for network based applications."
RDEPENDS:${PN}-slpd = " slpd-lite"
SUPPORTED_VENDOR:${PN}-slpd = "ALL"
#-----------------------------------#

SUMMARY:${PN}-lldpd = "AMI Core Features: Link Layer Discovery Protocol Daemon"
DESCRIPTION:${PN}-lldpd = " Allows BMCs to discover and communicate with network devices \
                            through LLDP, enhancing network visibility and management."
RDEPENDS:${PN}-lldpd = " lldpd"
SUPPORTED_VENDOR:${PN}-lldpd = "ALL"
#-----------------------------------#

SUMMARY:${PN}-bootlogo = "AMI Core Features: Bootlogo"
DESCRIPTION:${PN}-bootlogo = " Displays a custom logo during bmc boot "
RDEPENDS:${PN}-bootlogo = " psplash \
			    bootlogo "
SUPPORTED_VENDOR:${PN}-bootlogo = "EVB"
#-----------------------------------#

SUMMARY:${PN}-2fa = "AMI Core Features: Two Factor Authentication"
DESCRIPTION:${PN}-2fa = " Multifactor authentication which addional authentication while login"
RDEPENDS:${PN}-2fa = " google-authenticator-libpam \
                        web-two-factor-authentication"
SUPPORTED_VENDOR:${PN}-2fa = "ALL"
#-----------------------------------#

SUMMARY:${PN}-prov-mode-mgr = "AMI Core Features: Provosioning Mode Manager"
DESCRIPTION:${PN}-prov-mode-mgr = " This component is used to manage the RestrictionMode property \
					 under U-Boot environment variable using phosphor-u-boot-env-mgr"
RDEPENDS:${PN}-prov-mode-mgr = "  prov-mode-mgr \
				  phosphor-u-boot-mgr "
SUPPORTED_VENDOR:${PN}-prov-mode-mgr = "ALL"
#-----------------------------------#

SUMMARY:${PN}-rbc-mgr = "AMI Core Features: Remote Bios Config Manager"
DESCRIPTION:${PN}-rbc-mgr = " Remote BIOS Configuration (RBC) service exposes D-Bus methods for \
					BIOS settings management operations"
RDEPENDS:${PN}-rbc-mgr = " biosconfig-manager"
SUPPORTED_VENDOR:${PN}-rbc-mgr = "ALL"
#-----------------------------------#

SUMMARY:${PN}-host-interface = "AMI Core Features: Host Interface"
DESCRIPTION:${PN}-host-interface = " Add a systemd service that sets up a virtual Ethernet-over-USB interface for \
					communication between the Host and the BMC."
RDEPENDS:${PN}-host-interface = " host-interface"
SUPPORTED_VENDOR:${PN}-host-interface = "ALL"
#-----------------------------------#
# Firmware Update Features

SUMMARY:${PN}-image-sign = "AMI Core Features: Image Signing"
DESCRIPTION:${PN}-image-sign = "Supports to verify signature during Firmware update "
RDEPENDS:${PN}-image-sign = " \
			"
SUPPORTED_VENDOR:${PN}-image-sign = "ALL"
#-----------------------------------#

SUMMARY:${PN}-phosphor-ipmi-flash = "AMI Core Features: Phosphor IPMI Flash"
DESCRIPTION:${PN}-phosphor-ipmi-flash = "Support to Update Firmware via IPMI command"
RDEPENDS:${PN}-phosphor-ipmi-flash = " \
				phosphor-ipmi-flash \
				phosphor-ipmi-blobs \
			"
SUPPORTED_VENDOR:${PN}-phosphor-ipmi-flash = "ALL"
#-----------------------------------#

SUMMARY:${PN}-hw-failsafe-boot = "AMI Core Features: Dual Image Hardware Failsafe Boot"
DESCRIPTION:${PN}-hw-failsafe-boot = "Support to Recovery from Hardware Failure for dual image feature"
RDEPENDS:${PN}-hw-failsafe-boot = " \
			"
SUPPORTED_VENDOR:${PN}-hw-failsafe-boot = "ALL"
#-----------------------------------#

SUMMARY:${PN}-dual-image = "AMI Core Features : Dual Image"
DESCRIPTION:${PN}-dual-image = "This option enables ABR  with Dual SPI mode"
RDEPENDS:${PN}-dual-image = " \
				${PN}-hw-failsafe-boot \
				bmc-boot-check \
				emmc-enable \
			"
SUPPORTED_VENDOR:${PN}-dual-image = "ALL"
#-----------------------------------#

SUMMARY:${PN}-single-spi-abr = "AMI Core Features : Dual Image Single SPI ABR"
DESCRIPTION:${PN}-single-spi-abr = "This option enables ABR with Single SPI mode"
RDEPENDS:${PN}-single-spi-abr = " \
				${PN}-dual-image \
			"
SUPPORTED_VENDOR:${PN}-single-spi-abr = "ALL"
#-----------------------------------#

SUMMARY:${PN}-sync-conf = "AMI Core Features : Sync Configuration"
DESCRIPTION:${PN}-sync-conf = "Support to Sync Configuration in both SPI for Dual image"
RDEPENDS:${PN}-sync-conf = " \
				${PN}-dual-image \ 
				phosphor-software-manager-sync \
			"
SUPPORTED_VENDOR:${PN}-sync-conf = "ALL"

#-----------------------------------#

SUMMARY:${PN}-extlog = "AMI Core Features : Extlog Support"
DESCRIPTION:${PN}-extlog = "This feature will store the extendedlog data \
			    based on the configurations the request and response data \
			    of the incoming ipmi commands will be logged"
RDEPENDS:${PN}-extlog = " extlog-configs emmc-enable"
SUPPORTED_VENDOR:${PN}-extlog = "ALL"

#-----------------------------------#

SUMMARY:${PN}-nvidiasipack = "EP : NVIDIA Sipack"
DESCRIPTION:${PN}-nvidiasipack = "This package group contains the NVIDIA silicon pack features"
RDEPENDS:${PN}-nvidiasipack = " nvidia-otp-provisioning \
			nvidia-power-manager \
			nvidia-power-monitor \
			nvidia-shmem \
			nvidia-tal \
			nvidia-code-mgmt \
			nvidia-emmc-logging \
			nvidia-emmc-partition \
			nvidia-event-logs \
			nvidia-ipmi-oem \
			nvidia-mac-update \
			nvidia-mc-aspeed-lib \
			nvidia-mc-lib \
			nvidia-cperdecoder \
			nvidia-fpga-ready-monitor \
			nvidia-journal-conf \
			nvidia-oobaml \
			nvidia-rtc-ready \
			nvidia-vmep \
			nvidia-nvme-cpld \
			bmc-systemd-conf \
			bmc-pcie-init \
			bmc-post-boot-cfg \
			bmc-internal-network-config \
			libmctp \
			pldm \
			spdm \
			wd-systemd-conf \
			id-surrogate \
			log-once \
			powerctrl \
			secure-shell \
			set-hmc-time \
			write-protect \
			smbios-mdr \
			biosconfig-manager \
			phosphor-gpio-monitor \
			obmc-control-fan \
			obmc-phosphor-buttons "
SUPPORTED_VENDOR:${PN}-nvidiasipack = "NVIDIA"
ARCH_TYPE:${PN}-nvidiasipack = "ARM"
#-----------------------------------#

SUMMARY:${PN}-ipmi-ssif = "AMI Core Features: IPMI SSIF"
DESCRIPTION:${PN}-ipmi-ssif = "Phosphor OpenBMC SSIF to DBUS"
RPROVIDES:${PN}-ipmi-ssif += ""
RDEPENDS:${PN}-ipmi-ssif = " phosphor-ipmi-ssif "
SUPPORTED_VENDOR:${PN}-ipmi-ssif = "NVIDIA"
ARCH_TYPE:${PN}-ipmi-ssif = "ARM"
#-----------------------------------#

SUMMARY:${PN}-spdm = "AMI Core Features: SPDM Application Library"
DESCRIPTION:${PN}-spdm = "SPDM Application Library provide abstraction of \
				Secure Protocol Data Modelling (SPDM) API commands."
RDEPENDS:${PN}-spdm = " spdmd"
SUPPORTED_VENDOR:${PN}-spdm = "ALL"
#-----------------------------------#

#Network Features
SUMMARY:${PN}-network = "AMI Core Features: Network Support"
DESCRIPTION:${PN}-network = "Critical process, to be enabled always"
RDEPENDS:${PN}-network = " phosphor-network \
                           phosphor-ipmi-net \
                           systemd"
SUPPORTED_VENDOR:${PN}-network = "ALL"
RDEPENDS:${PN}-network:append:evb-ast2600 = " mac-hostname"
RDEPENDS:${PN}-network:append:evb-npcm845 = " phytool \
                                            "
#-----------------------------------#

SUMMARY:${PN}-network-system-firewall-support = "AMI Core Features: System Firewall Support"
DESCRIPTION:${PN}-network-system-firewall-support = "This feature allows users to define custom rules to protect BMC from packet-based attacks by specifying which packets to accept or drop."
RDEPENDS:${PN}-network-system-firewall-support = " phosphor-network iptables "
SUPPORTED_VENDOR:${PN}-network-system-firewall-support = "ALL"
#-----------------------------------#

SUMMARY:${PN}-network-advanced-route-support = "AMI Core Features: Advanced IP Routing Support"
DESCRIPTION:${PN}-network-advanced-route-support = "Advanced IP Routing support adds routing rules to control packet forwarding based on specific network conditions."
RDEPENDS:${PN}-network-advanced-route-support = " phosphor-network iproute2"
SUPPORTED_VENDOR:${PN}-network-advanced-route-support = "ALL"
#-----------------------------------#

SUMMARY:${PN}-network-bonding-support = "AMI Core Features: Network Bonding Support"
DESCRIPTION:${PN}-network-bonding-support = "This feature aggregates physical interfaces and represents one logical interface. 'active-backup' mode is supported which is network interface failover policy."
RDEPENDS:${PN}-network-bonding-support = " phosphor-network \
                                           phosphor-ipmi-net \
                                           systemd "
SUPPORTED_VENDOR:${PN}-network-bonding-support = "ALL"
#-----------------------------------#

SUMMARY:${PN}-network-openssl-support = "AMI Core Features: Openssl FIPS Support"
DESCRIPTION:${PN}-network-openssl-support = "OpenSSL FIPS (Federal Information Processing Standard) is a mode of OpenSSL that ensures cryptographic operations meet FIPS 140-2 security standards, providing a validated and secure environment for encryption and cryptographic modules used in sensitive applications."
RDEPENDS:${PN}-network-openssl-support = " openssl-manager "
SUPPORTED_VENDOR:${PN}-network-openssl-support = "ALL"
#-----------------------------------#

SUMMARY:${PN}-network-disable-ping-support = "AMI Core Features: Disable Ping Support"
DESCRIPTION:${PN}-network-disable-ping-support = "Disable ping (echo packets) which is required for security reasons."
RDEPENDS:${PN}-network-disable-ping-support = " phosphor-network "
SUPPORTED_VENDOR:${PN}-network-disable-ping-support = "ALL"
#-----------------------------------#

SUMMARY:${PN}-network-iperf3-support = "AMI Core Features: Iperf3 Tool Support"
DESCRIPTION:${PN}-network-iperf3-support = "Iperf3 is a network testing tool used to measure the bandwidth, latency, and performance of a network connection"
RDEPENDS:${PN}-network-iperf3-support = " iperf3 \
                                          systemd "
SUPPORTED_VENDOR:${PN}-network-iperf3-support = "ALL"
#-----------------------------------#

SUMMARY:${PN}-network-ncsi-support = "AMI Core Features: NCSI Support"
DESCRIPTION:${PN}-network-ncsi-support = "NCSI (Network Side Band Interface) is a management interface that allows remote monitoring and control of network devices, ensuring out-of-band management"
RDEPENDS:${PN}-network-ncsi-support = " phosphor-network \
                                        systemd \
                                        "
SUPPORTED_VENDOR:${PN}-network-ncsi-support = "ALL"
#-----------------------------------#

SUMMARY:${PN}-network-phy-configuration-support = "AMI Core Features: PHY configuration support"
DESCRIPTION:${PN}-network-phy-configuration-support = "Configures physical layer (PHY) settings for network interfaces, including auto-negotiation, speed, and duplex (half/full) modes."
RDEPENDS:${PN}-network-phy-configuration-support = " phosphor-network "
SUPPORTED_VENDOR:${PN}-network-phy-configuration-support = "ALL"
#-----------------------------------#

SUMMARY:${PN}-network-nsupdate-support = "AMI Core Features: DDNS Nsupdate Support"
DESCRIPTION:${PN}-network-nsupdate-support = "This feature allows dynamic updates to DNS records."
RDEPENDS:${PN}-network-nsupdate-support = " phosphor-network bind-utils "
SUPPORTED_VENDOR:${PN}-network-nsupdate-support = "ALL"
#-----------------------------------#

SUMMARY:${PN}-network-tsig-support = "AMI Core Features: DDNS TSIG Support"
DESCRIPTION:${PN}-network-tsig-support = "This feature provides secure authentication for DNS updates using shared secret keys."
RDEPENDS:${PN}-network-tsig-support = " phosphor-network bind-utils "
SUPPORTED_VENDOR:${PN}-network-tsig-support = "ALL"
#-----------------------------------#

SUMMARY:${PN}-network-persist-mac-support = "AMI Core Features: Persist Mac Support"
DESCRIPTION:${PN}-network-persist-mac-support = "This feature is to persist Mac accross uboot"
RDEPENDS:${PN}-network-persist-mac-support = " phosphor-network "
SUPPORTED_VENDOR:${PN}-network-persist-mac-support = "ALL"
#-----------------------------------#

SUMMARY:${PN}-network-avahi-support = "AMI Core Features: AVAHI support"
DESCRIPTION:${PN}-network-avahi-support = "This Feature enables automatic discovery and advertisement of network services and hosts using multicast DNS (mDNS) and DNS Service Discovery (DNS-SD)"
RDEPENDS:${PN}-network-avahi-support = " phosphor-network avahi-daemon "
SUPPORTED_VENDOR:${PN}-network-avahi-support = "ALL"
#-----------------------------------#

#Below are the Summary and description for LF features which are required for
#OneTree Dev Studio to show in UI

SUMMARY:obmc-bmc-state-mgmt = "BMC state management"
DESCRIPTION:obmc-bmc-state-mgmt = "Handles BMC state transitions and tracks its operational status"

SUMMARY:obmc-bmcweb = "bmcweb support"
DESCRIPTION:obmc-bmcweb = "Provides a REST API and web interface for BMC management"

SUMMARY:obmc-chassis-mgmt = "Chassis management"
DESCRIPTION:obmc-chassis-mgmt = "Chassis management oversees the state and operation of the chassis, including the Baseboard Management Controller (BMC) and host systems."

SUMMARY:obmc-chassis-state-mgmt = "Chassis state management"
DESCRIPTION:obmc-chassis-state-mgmt = "Handles power state transitions of the chassis"

SUMMARY:obmc-devtools = "Development tools"
DESCRIPTION:obmc-devtools = "Includes developing, debugging, and testing OpenBMC applications"

SUMMARY:obmc-fan-control = "Fan control management"
DESCRIPTION:obmc-fan-control = "Controls fan speed for thermal and power efficiency"

SUMMARY:obmc-fan-mgmt = "Fan management"
DESCRIPTION:obmc-fan-mgmt = "Manages fan presence, status, and basic operations(Deprecated - use obmc-fan-control instead)"

SUMMARY:obmc-flash-mgmt = "Flash management"
DESCRIPTION:obmc-flash-mgmt = "Supports firmware updates via BMC flash interfaces"

SUMMARY:obmc-host-ctl = "Host control"
DESCRIPTION:obmc-host-ctl = "Enables interaction and control of the host system"

SUMMARY:obmc-host-ipmi = "Host IPMI"
DESCRIPTION:obmc-host-ipmi = "Implements IPMI commands for host system control"

SUMMARY:obmc-host-state-mgmt = "Host state management"
DESCRIPTION:obmc-host-state-mgmt = "Handles state transitions of the host system"

SUMMARY:obmc-inventory = "Inventory support"
DESCRIPTION:obmc-inventory = "Tracks and updates hardware inventory data"

SUMMARY:obmc-leds = "LED applications"
DESCRIPTION:obmc-leds = "Manages LED indicators for status and diagnostics"

SUMMARY:obmc-logging-mgmt = "Logging management"
DESCRIPTION:obmc-logging-mgmt = "Captures logs and event messages for debugging"

SUMMARY:obmc-remote-logging-mgmt = "Remote logging management"
DESCRIPTION:obmc-remote-logging-mgmt = "Enables remote collection of system logs"

SUMMARY:obmc-net-ipmi = "Network IPMI support"
DESCRIPTION:obmc-net-ipmi = "Supports IPMI messaging over LAN"

SUMMARY:obmc-software = "Software management"
DESCRIPTION:obmc-software = "Manages firmware/software images and updates"

SUMMARY:obmc-system-mgmt = "System management"
DESCRIPTION:obmc-system-mgmt = "Provides core system services and controls"

SUMMARY:obmc-user-mgmt = "User management"
DESCRIPTION:obmc-user-mgmt = "Handles user accounts and access control"

SUMMARY:ssh-server-dropbear = "Lightweight SSH server"
DESCRIPTION:ssh-server-dropbear = "Provides a minimal and secure SSH server for remote access"

SUMMARY:obmc-debug-collector = "BMC debug collector"
DESCRIPTION:obmc-debug-collector = "Collects debug data for BMC issue analysis"

SUMMARY:obmc-network-mgmt = "Network management"
DESCRIPTION:obmc-network-mgmt = "Manages BMC network settings and interfaces"

SUMMARY:obmc-settings-mgmt = "Settings management"
DESCRIPTION:obmc-settings-mgmt = "Stores and retrieves system settings and configs"
#-----------------------------------#

#Tools
SUMMARY:${PN}-tools = "Unified toolset for platform management and diagnostics"
DESCRIPTION:${PN}-tools = "Command-line utilities bundled under a unified tool tree to support platform management, configuration, and diagnostics"
RDEPENDS:${PN}-tools = " ipmitool \
			 pwmtachtool \
			 adcapp \
			 i3c-tools "
SUPPORTED_VENDOR:${PN}-tools = "ALL"
#-----------------------------------#

SUMMARY:${PN}-pldm = "AMI Core Features: OneTree PLDM"
DESCRIPTION:${PN}-pldm = " OneTree PLDM for cross platform"
RDEPENDS:${PN}-pldm = " ot-pldm"
SUPPORTED_VENDOR:${PN}-pldm = "ALL"
#-----------------------------------#

SUMMARY:${PN}-bmc-services-ready = "AMI Core Features: OneTree BMC services ready"
DESCRIPTION:${PN}-bmc-services-ready = "Ensure BMC readiness for the customized services"
RDEPENDS:${PN}-bmc-services-ready = "bmc-services-ready"
SUPPORTED_VENDOR:${PN}-bmc-services-ready = "ALL"
#-----------------------------------#
