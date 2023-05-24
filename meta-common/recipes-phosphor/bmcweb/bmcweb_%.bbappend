FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON += "-Dredfish-dump-log=enabled"

# add "redfish-hostiface" group
GROUPADD_PARAM:${PN}:append = ";redfish-hostiface"

SRCREV = "188cb6294105a045a445619415d01843de8c3732"

#SRC_URI:append	= " file://0006-enabled-redfish-dump-log.patch "
#SRC_URI:append	= " file://0014-Add-Download-BMCDump-Support-in-Debug-Collector.patch "

SRC_URI:append = "file://0001-managers-add-factory-restore.patch \
	    file://0002-virtual-media-nfs-support.patch \
	    file://0003-Add_KVM_VM_status_in_user_session_info.patch \
	    file://0004-Added_Sevice_Conf_for_KVM_VM_SSLSOL.patch \
	    file://0005-added-IPv6StaticDefaultGateways-property.patch \
	    file://0007-Restricted-root-user-privilage.patch \
	    file://0008-enhanced-passwordpolicy.patch \
            file://0009-Post-Chassis.Reset-ChassisId-validation.patch \
            file://0010-Time-zone-configuration-support.patch \
            file://0011-Add-Chassis-Sensors-Collection.patch \
            file://0012-Added-PefService-and-SMTP-configuration.patch \
	    file://0015-added-OEM-led-indicator-amber-green-susack-status.patch \
	    file://0016-Added-OOB-Bios-Configuration-Support-in-Redfish.patch \
	    file://0017-Integrated-NVME-Interface.patch \
	    file://0018-Add-Redfish-Logs-for-Discrete-Sensors.patch \
            file://0019-IndicatorLED-Depreacted.patch \
            file://0020-Additional-Sensors-Support.patch \ 
            file://0021-Integrated-NIC-Interface-in-Redfish.patch \
	    file://0022-Fixed-the-Enable-Disable-outband-IPMI-issue.patch \
	    file://0023-Fix-for-unable-to-delete-newly-created-ipv4-static.patch \
            file://0024-Time-Zone-Configuration-issue-fix.patch \ 
	    file://0025-Add-Diag-and-Safe-Mode-Support.patch \
	    file://0026-fix-progress-not-getting-updated-issue.patch \
	    file://0027-Fix-KVM-disconnect-issue.patch \
	    file://0029-Fix-getting-empty-IP-address.patch \
"
SRC_URI_BHS:append ="file://0028-Adding-proper-path-to-get-the-cupsensors.patch \
"
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', SRC_URI_BHS, '', d)}"
