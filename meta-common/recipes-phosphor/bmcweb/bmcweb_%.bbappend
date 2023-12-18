FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON += "-Dredfish-dump-log=enabled"
EXTRA_OEMESON += "-Dredfish-new-powersubsystem-thermalsubsystem=enabled"
EXTRA_OEMESON += "-Dredfish-provisioning-feature=enabled"

# add "redfish-hostiface" group
GROUPADD_PARAM:${PN}:append = ";redfish-hostiface"

#SRCREV = "188cb6294105a045a445619415d01843de8c3732"
#SRCREV = "3e72c2027aa4e64b9892ab0d3970358ba446f1fa"
SRCREV = "0c2ba59dd0532480970517457fae9f4739790c81"

#SRC_URI:append	= " file://0006-enabled-redfish-dump-log.patch "

SRC_URI:append = "   \
	    file://0001-managers-add-factory-restore.patch  \
	    file://0002-virtual-media-nfs-support.patch \
	    file://0004-Added-Service-Config-for-KVM-SOL-Vmedia.patch \
	    file://0008-enhanced-passwordpolicy.patch \
            file://0009-Post-Chassis.Reset-ChassisId-validation.patch \
            file://0011-Add-Chassis-Sensors-Collection.patch \
	    file://0015-added-OEM-led-indicator-amber-green-susack-status-nd-IndicatorLed-depricated.patch \
	    file://0018-Add-Redfish-Logs-for-Discrete-Sensors.patch \
            file://0020-Additional-Sensors-Support.patch \
            file://0022-Fixed-the-Enable-Disable-outband-IPMI-issue.patch \
	    file://0025-Add-Diag-and-Safe-Mode-Support.patch \
	    file://0040-Fix-for-status-code-return-under-Chassis-URI.patch \
	    file://0049-Fix-for-DateTimeLocalOffset-return-code-status.patch \
	    file://0056-Added-Bios-Setting-URI-to-Bios.patch \
            file://0058-Removing-KVM-ServiceEnabled-property-under-manager.patch \
            file://0062-Fixed-VirtualMedia-not-listing-issue-under-Accounts.patch \ 
            file://0069-changing-the-error-code-of-non-writeable-error-messa.patch \
	    file://0070-Adding-successResponse-for-Factory-Default-Reset.patch \
            file://0063-Adding-success-message-resp-for-clearing-postcode-lo.patch \ 
            file://0044-Restrict-the-patch-of-IPv4-from-DHCP-to-Static-and-v.patch \
            file://0036-Add-Locked-status-to-login-API-on-User-locked.patch \
            file://0083-Fixed-201-response-code-appears-along-with-error-mes.patch \
            file://0084-Task-Delete-Implementation-Under-TaskService.patch \
            file://0086-Adding-SubordinateOverrides-privilege.patch \
            file://0092-Added-SessionType-as-Redfish-for-created-Redfish-Ses.patch \
            file://0093-Generating-logs-takes-a-long-time-set-timeout-to-20.patch \
            file://0099-Adding-Error-Message-for-Invalid-HostName.patch \
            file://0100-Adding-FRU-support-to-Redfish.patch \
            file://0101-Adding-Error-Message-for-Invalid-MTUSize.patch \
            file://0104-Fix-for-Display-Hostname-properly-in-NetworkProtocol.patch \
            file://0116-Redfish-Support-for-BSOD-Feature.patch \
            file://0117-Add-OS-Critical-Stop-Sensor-Redfish-Registry.patch \
	    file://Fixed-Clang-format-issues-in-Redfish-core.patch \
	    file://0012-Added-PefService-and-SMTP-configuration.patch \
	    file://0003-Add_KVM_VM_status_in_user_session_info.patch \
            file://0078-Fix-for-invalid-IPv6StaticAddresses-error-Message.patch \
            file://0115-Added-204-resp-code-Patch-MetricReportDefinitions.patch \
	    file://0074-Adding-400-Bad-request-response-for-invalid-MACAddre.patch \
	    file://0055-FIXES-TrustedModuleRequiredToBoot-Property-Patch-Iss.patch \
            file://0054-Fixed-the-unable-to-set-user-lockout-time-manual.patch \
	    file://0075-removing-getcertificate-call-from-replace-certificat.patch \
	    file://0071-Added-new-property-PasswordChangeRequired-to-create-newuser.patch \
	    file://0005-added-ipv6staticDefaultGateways-property.patch \
            file://0094-Fixed-Apache-Benchmark-tool-timeout-issue.patch \
            file://0124-Added-Success-Message-For-Clearing-Dump-Logs.patch \
	    file://0045-FIXES-LED-button-Display-issue-in-Overview-Page.patch \
            file://0107-Adding-error-message-for-LDAPService.patch \
	    file://0111-Adding-the-OEM-property-support-for-discrete-sensor.patch \
	    file://0077-ADDING-propertyNotWritable-Error-Message-for-ReadOnl.patch \
	    file://0017-Integrated-NVME-Interface.patch \
	    file://0031-Integrated-RAID-HBA-Interface.patch \
	    file://0010-Time-zone-configuration-support.patch \
	    file://0132-Added-OOB-BIOS-Configuration-Support.patch \
            file://0035-MaintenanaceWindow-OperationApplyTime-Recreation.patch \
            file://0085-Redfish-Service-validator-fixes.patch \
            file://0041-Fixed-PostEvent-RegistryPrefixe.patch \
            file://0021-Integrated-NIC-Interface-in-Redfish.patch \
	    file://0133-Add-Download-BMCDump-Support-in-Debug-Collector.patch \
            file://0060-Redesign-DHCPv4-DHCPv6-Enable-Disable-Flow-Limit-Sta.patch \
            file://0081-Closing-SSE-stream-when-Subscription-is-deleted.patch \
            file://0112-ByPass-authentication-for-requests-redirected.patch \
            file://0138-Fixed-Task-Monitor-response-after-Taskcompleted.patch \
            file://0139-Fix-For-Network-IPMI-Policy-in-Redfish.patch \
            file://0142-Redfish-Support-for-Delete-BSOD-image.patch \
            file://0154-Validate-IPv6-address.patch \
            file://0146-NTP-severs-count-fix-under-Network-protocol.patch \
            file://0155-Fixed-LocalRole-Patch-error-in-redfish.patch \
	    file://0156-Proper-https-status-while-array-size-exceeds-the-siz.patch \
            file://0153-Removing-NMI-Actions-from-Systems-URI.patch \
            file://0145-Fix-for-Duplicate-Etag-value-in-Redfish.patch \
	    file://0122-Added-Media-account-type-in-redfish.patch \
            file://0160-Update-DHCPEnabled-based-on-the-values-of-DHCPv4-DHC.patch \
            file://0150-Not-able-to-do-power-cycle-if-one-task-is-in-running.patch \
            file://0128-DDNS-Update-Feature-Support-in-Network.patch \
	    file://0123-Added-USB-PowerSave-Mode-Support-in-Redfish.patch \
            file://0147-Create-Subscription-with-SNMPTrap-for-MessageIds-and-RegistryPrefixes.patch \
            file://0152-Thrown-proper-error-message-for-POST-replace-certificate-in-CertificateService.patch \
            file://0149-Delete-other-existing-Ipv6Address-while-patch-new-Ip.patch \
            file://0159-Add-Error-message-when-create-Subscription-with-SubscriptionType-as-RedfishEvent.patch \
            file://0151-While-PATCH-in-AccountService-Thrown-proper-Error-message-for-RemoteRoleMapping.patch \
            file://0158-Fixed-invalid-staticNameServer-Error-Msg.patch \
            file://0143-Support-Bond-Feature-in-Network-via-Redfish.patch \
        "
SRC_URI_NON_PFR = " file://0067-adding-support-for-HttpPushUriTargets.patch "
SRC_URI:append = "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '', SRC_URI_NON_PFR, d)}"

SRC_URI_NM:append = "file://0083-modifing-the-error-when-initialization-mode-was-chan.patch \
"
SRC_URI_BHS:append = "file://0108-Adding-condition-to-Patch-Min-Value-not-greater-than.patch \
                      file://0110-Fix-For-Pmt-Sensor-Not-listed-in-Redfish.patch \
                      file://0118-removing-the-created-policy-get-calls-after-post.patch \
                      file://0134-StaticLoadfactor-patch-in-Dynamic-mode-issue.patch \
		      file://0136-support-domain-Capabilities-reset.patch \
"
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'restricted', SRC_URI_NM, '', d)}"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', "${@bb.utils.contains('BBFILE_COLLECTIONS', 'restricted', SRC_URI_BHS, '', d)}", '', d)}"

#EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '',' -Dhttp-body-limit=68 ', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_INSTALL', 'nvme-mgmt', ' -Dnvme-enable-path=/xyz/openbmc_project/Nvme','', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_INSTALL', 'nvmebasic-mgmt', ' -Dnvme-enable-path=/xyz/openbmc_project/NvmeBasic','', d)}"

DEPENDS += "phosphor-snmp"
