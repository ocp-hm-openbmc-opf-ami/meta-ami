FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON += "-Dredfish-dump-log=enabled"
EXTRA_OEMESON += "-Dredfish-new-powersubsystem-thermalsubsystem=enabled"
EXTRA_OEMESON += "-Dredfish-provisioning-feature=enabled"

# add "redfish-hostiface" group
GROUPADD_PARAM:${PN}:append = ";redfish-hostiface"

#SRCREV = "188cb6294105a045a445619415d01843de8c3732"
SRCREV = "3e72c2027aa4e64b9892ab0d3970358ba446f1fa"

#SRC_URI:append	= " file://0006-enabled-redfish-dump-log.patch "

SRC_URI:append = " file://0001-managers-add-factory-restore.patch  \
	    file://0002-virtual-media-nfs-support.patch \
	    file://0004-Added_Sevice_Conf_for_KVM_VM_SSLSOL.patch \
	    file://0007-Restricted-root-user-privilage.patch \
	    file://0008-enhanced-passwordpolicy.patch \
            file://0009-Post-Chassis.Reset-ChassisId-validation.patch \
            file://0011-Add-Chassis-Sensors-Collection.patch \
	    file://0012-Added-PefService-and-SMTP-configuration.patch \
	    file://0014-Add-Download-BMCDump-Support-in-Debug-Collector.patch \
	    file://0015-added-OEM-led-indicator-amber-green-susack-status.patch \
	    file://0016-Added-OOB-Bios-Configuration-Support-in-Redfish.patch \
	    file://0017-Integrated-NVME-Interface.patch \
	    file://0018-Add-Redfish-Logs-for-Discrete-Sensors.patch \
            file://0019-IndicatorLED-Depreacted.patch \
            file://0020-Additional-Sensors-Support.patch \ 
            file://0021-Integrated-NIC-Interface-in-Redfish.patch \
            file://0022-Fixed-the-Enable-Disable-outband-IPMI-issue.patch \
	    file://0025-Add-Diag-and-Safe-Mode-Support.patch \
	    file://0031-Integrated-RAID-HBA-Interface.patch \
	    file://0040-Fix-for-status-code-return-under-Chassis-URI.patch \
	    file://0041-POST-Event-Subscription-with-Base-as-RegistryPrefixe.patch \
	    file://0047-Fix-for-Unauthorized-OOB-user-in-bmcweb.patch \
	    file://0049-Fix-for-DateTimeLocalOffset-return-code-status.patch \
            file://0054-Fix-for-Unable-to-set-User-lockout-time-manual.patch \
	    file://0056-Added-Bios-Setting-URI-to-Bios.patch \
            file://0058-Removing-KVM-ServiceEnabled-property-under-manager.patch \ 
            file://0062-Fixed-VirtualMedia-not-listing-issue-under-Accounts.patch \ 
            file://0064-Fix-for-Empty-response-body-for-updating-username.patch \
            file://0069-changing-the-error-code-of-non-writeable-error-messa.patch \
	    file://0070-Adding-successResponse-for-Factory-Default-Reset.patch \
	    file://0074-Adding-400-Bad-request-response-for-invalid-MACAddre.patch \
            file://0063-Adding-success-message-resp-for-clearing-postcode-lo.patch \ 
	    file://0067-adding-support-for-HttpPushUriTargets.patch \
            file://0066-DateTime-patch-error.patch \
            file://0048-changing-maximum-supported-kvm-session-value-to-1.patch \
            file://0044-Restrict-the-patch-of-IPv4-from-DHCP-to-Static-and-v.patch \
            file://0075-removing-getcertificate-call-from-replace-certificat.patch \
            file://0005-added-IPv6StaticDefaultGateways-property.patch \
            file://0010-Time-zone-configuration-support.patch \
            file://0035-MaintenanaceWindow-OperationApplyTime-Recreation.patch \
            file://0079-To-get-Status-code-as-200OK-with-NoOperation.patch \
	    file://0003-Add_KVM_VM_status_in_user_session_info.patch \
	    file://0045-FIXES-LED-button-Display-issue-in-Overview-Page.patch \
	    file://0055-FIXES-TrustedModuleRequiredToBoot-Property-Patch-Iss.patch \
	    file://0077-ADDING-propertyNotWritable-Error-Message-for-ReadOnl.patch \
            file://0061-Fix-for-Incorrect-status-code-return-under-accounts.patch \
            file://0078-Fix-for-invalid-IPv6StaticAddresses-error-Message.patch \
	    file://0076-Implemented-SNMPTrap-in-Redfish-Event-Service.patch \
            file://0060-Redesign-DHCPv4-DHCPv6-Enable-Disable-Flow-Limit-Sta.patch \
            file://0036-Add-Locked-status-to-login-API-on-User-locked.patch \
	    file://0071-Added-new-property-PasswordChangeRequired-to-create-newuser.patch \
            file://0083-Fixed-201-response-code-appears-along-with-error-mes.patch \
            file://0082-IBMConfigFile-is-added-Event-Subscription-ResourceTy.patch \
            file://0084-Task-Delete-Implementation-Under-TaskService.patch \ 
	    file://0080-Added-PasswordRestFailed-after-password-expired.patch \
            file://0086-Adding-SubordinateOverrides-privilege.patch \
        "
SRC_URI_NM:append = "file://0083-modifing-the-error-when-initialization-mode-was-chan.patch \
"
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'restricted', SRC_URI_NM, '', d)}"

#EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '',' -Dhttp-body-limit=68 ', d)}"

DEPENDS += "phosphor-snmp"
