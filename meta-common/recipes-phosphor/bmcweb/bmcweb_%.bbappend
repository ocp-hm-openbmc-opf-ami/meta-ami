FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-managers-add-factory-restore.patch"
SRC_URI += "file://0002-Add_KVM_VM_status_in_user_session_info.patch"
SRC_URI += "file://0002-virtual-media-nfs-support.patch \
	    file://0004-Added_Sevice_Conf_for_KVM_VM_SSLSOL.patch \
            file://0006-Add-Chassis-Sensors-Collection.patch \
	    file://0007-Restricted-root-user-privilage.patch \
	    file://0008-enhanced-passwordpolicy.patch \
           "
