FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON += "-Dredfish-dump-log=enabled"

SRCREV = "188cb6294105a045a445619415d01843de8c3732"


SRC_URI += "file://0001-managers-add-factory-restore.patch \
	    file://0002-virtual-media-nfs-support.patch \
	    file://0003-Add_KVM_VM_status_in_user_session_info.patch \
	    file://0004-Added_Sevice_Conf_for_KVM_VM_SSLSOL.patch \
	    file://0005-added-IPv6StaticDefaultGateways-property.patch \
	    file://0006-enabled-redfish-dump-log.patch \ 
	    file://0007-Restricted-root-user-privilage.patch \
	    file://0008-enhanced-passwordpolicy.patch \
            file://0009-Post-Chassis.Reset-ChassisId-validation.patch \
            file://0010-Time-zone-configuration-support.patch \
            file://0011-Add-Chassis-Sensors-Collection.patch \
"
