FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON += "-Dredfish-dump-log=enabled"

SRC_URI += "file://0001-managers-add-factory-restore.patch \
	    file://0002-virtual-media-nfs-support.patch \
	    file://0003-Add_KVM_VM_status_in_user_session_info.patch \
	    file://0004-Added_Sevice_Conf_for_KVM_VM_SSLSOL.patch \
	    file://0005-added-IPv6StaticDefaultGateways-property.patch \
	    file://0006-enabled-redfish-dump-log.patch \ 
	    file://0007-Restricted-root-user-privilage.patch \
	    file://0008-enhanced-passwordpolicy.patch \
"
