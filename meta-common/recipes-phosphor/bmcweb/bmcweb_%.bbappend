FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON += "-Dredfish-dump-log=enabled"
EXTRA_OEMESON += "-Dredfish-new-powersubsystem-thermalsubsystem=enabled"
EXTRA_OEMESON += "-Dredfish-provisioning-feature=enabled"
EXTRA_OEMESON += "-Dredfish-dbus-log=enabled"

# add "redfish-hostiface" group
GROUPADD_PARAM:${PN}:append = ";redfish-hostiface"

SRCREV = "a88942019fdd3d8fc366999f7c178f3e1c18b2fe"

#SRC_URI:append	= " file://0006-enabled-redfish-dump-log.patch "

SRC_URI:append = "   \
	    file://0001-managers-add-factory-restore.patch  \
	    file://0002-virtual-media-nfs-support.patch \
	    file://0004-Added-Service-Config-for-KVM-SOL-Vmedia.patch \
            file://0009-Post-Chassis.Reset-ChassisId-validation.patch \
            file://0011-Add-Chassis-Sensors-Collection.patch \
	    file://0015-added-OEM-led-indicator-amber-green-susack-status-nd-IndicatorLed-depricated.patch \
            file://0020-Additional-Sensors-Support.patch \
            file://0022-Fixed-the-Enable-Disable-outband-IPMI-issue.patch \
	    file://0025-Add-Diag-and-Safe-Mode-Support.patch \
	    file://0040-Fix-for-status-code-return-under-Chassis-URI.patch \
	    file://0049-Fix-for-DateTimeLocalOffset-return-code-status.patch \
	    file://0056-Added-Bios-Setting-URI-to-Bios.patch \
            file://0058-Removing-KVM-ServiceEnabled-property-under-manager.patch \
            file://0062-Fixed-VirtualMedia-not-listing-issue-under-Accounts.patch \ 
            file://0069-changing-the-error-code-of-non-writeable-error-messa.patch \
            file://0044-Restrict-the-patch-of-IPv4-from-DHCP-to-Static-and-v.patch \
            file://0083-Fixed-201-response-code-appears-along-with-error-mes.patch \
            file://0084-Task-Delete-Implementation-Under-TaskService.patch \
            file://0086-Adding-SubordinateOverrides-privilege.patch \
            file://0092-Added-SessionType-as-Redfish-for-created-Redfish-Ses.patch \
            file://0101-Adding-Error-Message-for-Invalid-MTUSize.patch \
            file://0104-Fix-for-Display-Hostname-properly-in-NetworkProtocol.patch \
            file://0116-Redfish-Support-for-BSOD-Feature.patch \
	    file://0012-Added-PefService-and-SMTP-configuration.patch \
            file://0078-Fix-for-invalid-IPv6StaticAddresses-error-Message.patch \
            file://0115-Added-204-resp-code-Patch-MetricReportDefinitions.patch \
	    file://0074-Adding-400-Bad-request-response-for-invalid-MACAddre.patch \
	    file://0055-FIXES-TrustedModuleRequiredToBoot-Property-Patch-Iss.patch \
            file://0054-Fixed-the-unable-to-set-user-lockout-time-manual.patch \
	    file://0075-removing-getcertificate-call-from-replace-certificat.patch \
	    file://0005-added-ipv6staticDefaultGateways-property.patch \
            file://0124-Added-Success-Message-For-Clearing-Dump-Logs.patch \
            file://0107-Adding-error-message-for-LDAPService.patch \
            file://0041-Fixed-PostEvent-RegistryPrefixe.patch \
            file://0081-Closing-SSE-stream-when-Subscription-is-deleted.patch \
            file://0112-ByPass-authentication-for-requests-redirected.patch \
            file://0138-Fixed-Task-Monitor-response-after-Taskcompleted.patch \
            file://0139-Fix-For-Network-IPMI-Policy-in-Redfish.patch \
            file://0142-Redfish-Support-for-Delete-BSOD-image.patch \
            file://0146-NTP-severs-count-fix-under-Network-protocol.patch \
            file://0155-Fixed-LocalRole-Patch-error-in-redfish.patch \
            file://0153-Removing-NMI-Actions-from-Systems-URI.patch \
            file://0147-Create-Subscription-with-SNMPTrap-for-MessageIds-and-RegistryPrefixes.patch \
            file://0152-Thrown-proper-error-message-for-POST-replace-certificate-in-CertificateService.patch \
            file://0149-Delete-other-existing-Ipv6Address-while-patch-new-Ip.patch \
            file://0151-While-PATCH-in-AccountService-Thrown-proper-Error-message-for-RemoteRoleMapping.patch \
            file://0158-Fixed-invalid-staticNameServer-Error-Msg.patch \
            file://0143-Support-Bond-Feature-in-Network-via-Redfish.patch \
            file://0168-Fix-the-datatype-Error-in-Memory-Instance.patch \
            file://0165-Generating-proper-SSE-Id.patch \
            file://0135-Enabled-Dbus-Sel-Logging-Support.patch \
            file://0150-Redfish-Support-for-Trigger-BSOD.patch \
            file://0161-While-POST-Invalid-KeyCurveId-in-CertificateService-get-proper-Error-Msg.patch \
            file://0168-Enabled-DestinationType-when-Event-is-triggered-for-created-SNMP-Subscription.patch \
            file://0175-solution-for-kvm-websocket-session-out.patch \
            file://0176-Add-Restart-always-to-unit-service-file.patch \
            file://0166-While-POST-in-sessionService-include-X-XSS-Protection-header.patch \
            file://0172-Provide-delay-for-set-SSH-properties.patch \
            file://0178-Added-Error-Message-for-Multiple-IPv6StaticDefaultGa.patch \
            file://0173-Fixed-500-InternalError-in-trigger_PostCall.patch \
            file://0183-Added-the-condition-to-check-IPV6-is-DHCP-while-patch-IPv6StaticDefaultGateways.patch \
	    file://Fixed-Clang-format-issues-in-Redfish-core.patch \
	    file://0111-Adding-the-OEM-property-support-for-discrete-sensor.patch \
            file://0008-enhanced-passwordPolicy.patch \
	    file://0045-FIXES-LED-button-Display-issue-in-Overview-Page.patch \
            file://0176-powersubsystem-powersupply-properties.patch \
	    file://0036-Add-Locked-status-to-login-API-on-User-locked.patch \
            file://0145-Fix-for-Duplicate-Etag-value-in-Redfish.patch \
            file://0154-validate-ipv4-and-ipv6-address.patch \
            file://0162-While-Patch-DHCPv4-and-DHCPv6-Attribute-throw-500-In.patch \
	    file://0003-Add_KVM_VM_status_in_user_session_info.patch \
            file://0159-Add-Error-message-when-create-Subscription-with-SubscriptionType-as-RedfishEvent.patch \
            file://0180-Added-Property-Value-Incorrect-error-message-while-post-invalid-vlanid.patch \
            file://0085-Redfish-Service-validator-fixes.patch \
            file://0094-Fixed-Apache-Benchmark-tool-timeout-issue.patch \
            file://0010-Time-zone-configuration-support.patch \
            file://0100-Adding-FRU-support-to-Redfish.patch \
	    file://0071-Added-new-property-PasswordChangeRequired-to-create-newuser.patch \
	    file://0017-Integrated-NVME-Interface.patch \
	    file://0031-Integrated-RAID-HBA-Interface.patch \
	    file://0122-Added-Media-account-type-in-redfish.patch \
	    file://0157-Added-Redfish-Support-for-BRCM-PCIE-Switch.patch \
            file://0035-MaintenanaceWindow-OperationApplyTime-Recreation.patch \
	    file://0077-ADDING-propertyNotWritable-Error-Message-for-ReadOnl.patch \
	    file://0021-Integrated-NIC-Interface-in-Redfish.patch \
            file://0128-DDNS-Update-Feature-Support-in-Network.patch \
	    file://0123-Added-Power-Save-Mode-Support-in-KVM-and-VMedia.patch \
            file://0164-Redesign-DHCPv4-DHCPv6-Enable-Disable-Flow-Restrict-.patch \
	    file://0177-Fixed-invalid-subnetmask-IP.patch \
            file://0150-Not-able-to-do-power-cycle-if-one-task-is-in-running.patch \
            file://0018-Adding-Messege-registry-entry.patch \
	    file://0132-Added-OOB-BIOS-Configuration-Support-in-Redfish.patch \
            file://0185-Fixed-System-reset-action-giving-internal-error-at-MaintenanceWindow.patch \
	    file://0188-Arranging-the-error-message.patch \
	    file://0189-Disabling-Power-URI-and-Adding-PropertyNotWritable-E.patch \
            file://0190-Fixed-sync-Redfish-Service-Validator-failures.patch \
            file://0191-Fix-Parse-Error-The-Server-returned-a-malformed-resp.patch \
            file://0196-Fix-for-nfs-bad-dbus-request-error.patch \
            file://0198-Added-Delete-Method-for-task-monitor-Uri.patch \
	    file://0204-updating-last-activity-time-when-kvm-data-transfer.patch \
            file://0208-Fix-for-TaskStatus-should-not-be-set-until-the-task-Completed.patch \
            file://0192-Firewall-Feature-Support-in-Redfish.patch \
            file://0193-NodeManager.ChangeState-returns-204-response.patch \
            file://0207-Set-Sensor-Reading-fractional-value-as-4-digits.patch \
            file://0187-Receiving-SubmitTestEvent-in-SSE.patch \
            file://0209-Thrown-proper-error-message-for-POST-certificate.patch \
            file://0201-Triggering-power-operation-on-MaintenanceWindow-time.patch \
            file://0181-Fix-for-Duplicate-Error-Message-in-BIOS_URI.patch \
            file://0213-Delete-Deprecated-URI-and-properties-in-Redfish.patch \
            file://0212-Added-the-Error-message-when-both-Ipv4StaticAddress-and-Gateway-are-equal.patch \
            file://0214-Added-SNMPTrap-in-Redfish-Event-Service.patch \
            file://0215-Add-Proper-Logic-for-IP-Same-Series-Check.patch \
            file://0218-SNMP-Send-Test-Support-in-Redfish.patch \
            file://0202-Smtp-Mail-Alert-Support-in-Redfish.patch \
            file://0210-Redfish-Support-SMTP-server-switch-SSL-Security.patch \
            file://0220-Restrict-special-characters-in-NTPServers.patch \
            file://0221-NTPServer-out-of-lime-return-PropertyValueOutOfRange.patch \
            file://0211-Fixed-ErrorCode-in-eventServiceSSE.patch \
            file://0223-Added-Error-message-for-patching-Empty-Objects.patch \
	    file://0206-Added-post-call-for-BRCM-PCIE-switch.patch \
            file://0200-Added-the-Condition-to-verify-IPV6-is-DHCP-while-patch-IPv6StaticDefaultGateways.patch \
            file://0226-Fixed-pipeline-errors.patch \
            file://0233-To-print-Proper-error-message-in-insertmedia.patch \
            file://0219-Throw-error-when-IPv4StaticAddresses-Address-equals-Gateway.patch \
            file://0229-Patch-valid-NTP-servers.patch \
            file://0232-Throw-OperationNotAllowed-error-message-in-InsertMedia.patch \
            file://0228-Update-IPv4-and-IPv6-StaticAddressess-in-Single-Patch.patch \
            file://0195-Fix-for-getting-an-error-when-manually-setting-the-date-and-time.patch \
            file://0235-Added-Openbmc-Object-in-Smtp.patch \
            file://0194-Reduce-RoleId-duplicate-response.patch \
            file://0222-Added-New-Method-for-BRCM-and-MSCC-Raid.patch \
            file://0236-Certificate-error-handle-and-fix-the-status-code.patch \
            file://0225-SMTP-Redfish-support-for-Escalate-by-severity-level.patch \
            file://0241-Rearrage-the-Order-of-verifying-the-Version.patch \
            file://0216-Exist-CredentialBootstrapping-Account.patch \
	    file://0240-Added-License-Control-Feature-Support-in-Redfish.patch \
            file://0237-Delete-the-return-statement-and-continue-next-validation.patch \
            file://0234-Fix-for-enable-the-interface-combined-with-other-patch-operation-results-in-internal-server-error.patch \
            file://0227-TLS-SSL-name-should-not-be-a-static.patch \
            file://0238-update-Message.ExtendedInfo-for-ComputerSystem.Reset.patch \
            file://0230-Fixed-dateTime-changes-in-patch.patch \
            file://0248-RedFish-support-for-BandExternal.patch \
            file://0244-Added-the-error-message-when-trying-to-confgure-more-than-two-VLANs.patch \ 
            file://0249-Fix-for-ipv4-disappears-while-Setting-invalid-subnet.patch \
	    file://0203-Fixed-USB0-interface-dhcp-and-MACAddress-configs.patch \
            file://0245-get-NetworkInterfaces-instances.patch \
	    file://0246-Added-session-timeout-and-Port-info.patch \
            file://0250-Fixed-internal-error-500.patch \
            file://0247-Fix-for-Redfish-Reference-Checker.patch \
            file://0051-Changing-MaxConcurrentSessions-value-to-1.patch \
            file://0243-Change-the-value-of-Chassis-Instance-Sensors-Voltage-ReadingRangeMax-to-4-digits-after-decimal.patch \
            file://0186-Fix-for-Download-the-EventLog-in-WebUI.patch \
            file://0231-Session-Management-Implementation-under-Redfish.patch \
            file://0237-oem-sensor-history.patch \
            file://0252-Fixed-IPMI-protocol-in-a-false-state.patch \
            file://0253-Add-Hostname-and-Domainname-validations-for-FQDN-Att.patch \
            file://0205-List-missed-sensors-in-redfish-call.patch \
        "

SRC_URI_NON_PFR = " file://0067-adding-support-for-HttpPushUriTargets.patch \
		    file://0197-Add-support-to-update-both-BMC-active-and-Backup-ima.patch \
            file://0242-Add-support-to-applytime-property.patch \
"
SRC_URI:append = "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '', SRC_URI_NON_PFR, d)}"
SRC_URI_NM:append = "file://0083-modifing-the-error-when-initialization-mode-was-chan.patch \
"
SRC_URI_BHS:append = "file://0108-Adding-condition-to-Patch-Min-Value-not-greater-than.patch \
                      file://0110-Fix-For-Pmt-Sensor-Not-listed-in-Redfish.patch \
                      file://0118-removing-the-created-policy-get-calls-after-post.patch \
                      file://0134-StaticLoadfactor-patch-in-Dynamic-mode-issue.patch \
		      file://0136-support-domain-Capabilities-reset.patch \
"
#SRC_URI:append:evb-ast2600   = "file://0179-Fixed-RestoreOptions-in-EVB.patch "

EVB:append = "file://0179-Fixed-RestoreOptions-in-EVB.patch "  
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'evb', EVB, '', d)}"

AST2700:append = "file://0236-Fix-for-Compilation-Error-in-AST2700-build.patch"
SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'aspeed-sdk-layer', AST2700, '', d)}"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'restricted', SRC_URI_NM, '', d)}"

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', "${@bb.utils.contains('BBFILE_COLLECTIONS', 'restricted', SRC_URI_BHS, '', d)}", '', d)}"

SRC_URI_PFR = " file://0184-PFR-update-task-state-modifications-OT-2950.patch"
SRC_URI:append = "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', SRC_URI_PFR, '', d)}"

#EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '',' -Dhttp-body-limit=68 ', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_INSTALL', 'nvme-mgmt', ' -Dnvme-enable-path=/xyz/openbmc_project/Nvme','', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_INSTALL', 'nvmebasic-mgmt', ' -Dnvme-enable-path=/xyz/openbmc_project/NvmeBasic','', d)}"

DEPENDS += "phosphor-snmp"

