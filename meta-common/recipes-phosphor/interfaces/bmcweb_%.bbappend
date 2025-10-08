# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI = "git://github.com/openbmc/bmcweb.git;branch=master;protocol=https"
SRCREV = "a88942019fdd3d8fc366999f7c178f3e1c18b2fe"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Enable new power and thermal subsystem
EXTRA_OEMESON += " -Dredfish-new-powersubsystem-thermalsubsystem=enabled"
EXTRA_OEMESON += " -Dredfish-allow-deprecated-power-thermal=disabled"

# Enable Content-Type validation
EXTRA_OEMESON += " -Dinsecure-ignore-content-type=disabled"

#SRC_URI += " \
#            file://0001-Firmware-update-configuration-changes.patch \
#            file://0002-Use-chip-id-based-UUID-for-Service-Root.patch \
#            file://0010-managers-add-attributes-for-Manager.CommandShell.patch \
#            file://0011-bmcweb-Add-PhysicalContext-to-Thermal-resources.patch \
#            file://0012-Log-RedFish-event-for-Invalid-login-attempt.patch \
#            file://0014-recommended-fixes-by-crypto-review-team.patch \
#            file://0015-Add-state-sensor-messages-to-the-registry.patch \
#            file://0016-Fix-bmcweb-crashes-if-socket-directory-not-present.patch \
#            file://0018-bmcweb-Add-BMC-Time-update-log-to-the-registry.patch \
#            file://0020-Redfish-Deny-set-AccountLockDuration-to-zero.patch \
#            file://0023-Add-get-IPMI-session-id-s-to-Redfish.patch \
#            file://0024-Add-count-sensor-type.patch \
#            file://0029-Added-support-for-patching-sensors-under-Chassis-Sen.patch \
#            file://0032-systems-Add-pfr-and-cpld-postcode.patch \
#            file://0034-Add-Model-to-ProcessorSummary.patch \
#            file://0035-ExtendTimer-increased-to-6-mins-for-IFWI-update.patch \
#            file://0036-Add-Power-supplies-under-PowerSubsystem.patch \
#            file://0038-Image-Directory-made-as-Configurable-Parameter.patch \
#            file://0039-Revert-Remove-redfish-post-to-old-updateservice.patch \
#            file://0040-Add-ThermalSubsystem-Fan-Collection-and-Instances-and-FanRedundancy.patch \
#            file://0042-Add-Members-to-PowerSupplies.patch \
#            file://0043-Add-PowerCapacityWatts-instead-on-PowerInputwatts.patch \
#            file://0045-Increase-crashdump-Task-timeout.patch \
#            file://0046-Fix-redundancy-attribute-issue-for-Power-Supply-URI.patch \
#"
#
## OOB Bios Config:
#SRC_URI += " \
#            file://biosconfig/0001-Define-Redfish-interface-Registries-Bios.patch \
#            file://biosconfig/0002-BaseBiosTable-Add-support-for-PATCH-operation.patch \
#            file://biosconfig/0003-Add-support-to-ResetBios-action.patch \
#            file://biosconfig/0004-Add-support-to-ChangePassword-action.patch \
#            file://biosconfig/0005-Fix-remove-bios-user-pwd-change-option-via-Redfish.patch \
#            file://biosconfig/0006-Add-fix-for-broken-feature-Pending-Attributes.patch \
#            file://biosconfig/0007-Add-BiosAttributeRegistry-node-under-Registries.patch \
#"
#
## Virtual Media: Backend code is not upstreamed so downstream only patches.
#SRC_URI += " \
#            file://vm/0001-Revert-Disable-nbd-proxy-from-the-build.patch \
#            file://vm/0003-Apply-async-dbus-API.patch \
#            file://vm/0005-Add-handlers-for-patch-put-delete.patch \
#"
#
## EventService: Temporary pulled to downstream. See eventservice\README for details
#SRC_URI += " \
#            file://eventservice/0001-Conditional-verify-certificate-check-in-HttpClient.patch \
#            file://eventservice/0002-Remove-Base-registry-from-Supported-Registries.patch \
#            file://eventservice/0004-Log-Redfish-Events-for-all-subscription-actions.patch \
#            file://eventservice/0006-DeliveryRetryPolicy-support-for-EventDestination.patch \
#            file://eventservice/0007-Add-Configure-Self-support-for-Event-Subscriptions.patch \
#            file://eventservice/0008-Adopt-upstream-ConnectionPolicy.patch \
#            file://eventservice/0009-Fix-SSE-Subscription-with-upstream-sync.patch \
#            file://eventservice/0010-Add-EventService-SSE-filter-support.patch \
#            file://eventservice/0011-Fix-for-EventService-subscription-collection-fail.patch \
#"
#
## Temporary downstream mirror of upstream patches, see telemetry\README for details
#SRC_URI += " file://telemetry/0001-Revert-Remove-LogService-from-TelemetryService.patch \
#             file://telemetry/0006-Improved-telemetry-service-error-handling.patch \
#             file://telemetry/0007-Add-telemetry-triggers-to-the-message-registry.patch \
#             file://telemetry/0008-Restore-PUT-method-for-MRD.patch \
#"
#
## Temporary downstream patch for routing and privilege changes
#SRC_URI += " \
#            file://http_routing/0001-Fix-Adaptor-scope-issue-in-upgraded-connection.patch \
#            file://http_routing/0002-Move-privileges-to-separate-entity.patch \
#            file://http_routing/0003-Add-Privileges-to-SSE-and-Websockets.patch \
#            file://http_routing/0004-Dynamic-request-body-size-limit.patch \
#"
#
## ACPI LogService:
#SRC_URI += " \
#            file://acpi_logservice/0001-Adding-acpi-LogService.patch \
#"
#
## Node-manager:
#FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}/node-manager:"
#SRC_URI += "file://power_utility.hpp;subdir=git/redfish-core/lib/node-manager \
#            file://power.hpp;subdir=git/redfish-core/lib/node-manager \
#            file://node_manager.hpp;subdir=git/redfish-core/lib/node-manager \
#            file://domains_collection.hpp;subdir=git/redfish-core/lib/node-manager \
#            file://nm_common.hpp;subdir=git/redfish-core/lib/node-manager \
#            file://policies_collection.hpp;subdir=git/redfish-core/lib/node-manager \
#            file://throttling_status.hpp;subdir=git/redfish-core/lib/node-manager \
#            file://triggers.hpp;subdir=git/redfish-core/lib/node-manager \
#            file://node-manager/0001-Using-local-power.hpp-file-instead-of-upstreamed.patch \
#            file://node-manager/0002-Set-of-new-MessageEntries-added-for-the-NM.patch \
#            file://node-manager/0003-Add-NodeManager-schema-files.patch \
#            file://node-manager/0004-Add-node-manager-endpoint.patch \
#"
## OOB Config features:
#SRC_URI += " \
#            file://oob-config/0001-Adding-schema-for-OnDemand-Oem-URI-s.patch \
#            file://oob-config/0002-Optimising-the-License-Service-as-per-the-review-com.patch \
#            file://oob-config/0003-Fix-for-Redfish-Validator-LicenseService.patch \
#"
#
## Telemetry Features:
#SRC_URI += " \
#            file://telemetry-pkg/0001-cups-service-schema-XML-files-added.patch \
#            file://telemetry-pkg/0002-cups-service-features-added.patch \
#            file://telemetry-pkg/0003-Kafka-streaming-configuration-support.patch \
#            file://telemetry-pkg/0004-Redfish-Schema-for-Kafka-Streaming-Support.patch \
#            file://telemetry-pkg/0005-Add-PMT-kafka-streaming-messege-to-RF-registry.patch \
#"
#
## FIPS Enablement
#SRC_URI += " \
#            file://fips-enablement/0001-FIPS-Add-route-in-Managers.patch \
#            file://fips-enablement/0002-Add-FIPS-Manager.patch \
#            file://fips-enablement/0003-Add-FIPS-Route-in-Redfish.patch \
#"

# Enable PFR support
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '-Dredfish-provisioning-feature=enabled', '', d)}"

#Enable Secure boot support
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-secboot', '-Dredfish-provisioning-feature=enabled', '', d)}"

# Enable NBD proxy embedded in bmcweb
EXTRA_OEMESON += " -Dvm-nbdproxy=enabled"

# Disable dependency on external nbd-proxy application
EXTRA_OEMESON += " -Dvm-websocket=disabled"
EXTRA_OEMESON += " -Dredfish-host-logger=disabled"

# image-payload-limit will configure the max size of image file in MB which can be uploaded to bmcweb over https.
EXTRA_OEMESON += " -Dimage-payload-limit=129"
# http-body-limit will configure the max size of http request body in KB
EXTRA_OEMESON += " -Dhttp-body-limit=128"
EXTRA_OEMESON += " -Dimage-upload-dir=/tmp/images/"
RDEPENDS:${PN}:remove = " jsnbd"

do_install:append(){
	install -d ${D}/var/lib/bmcweb
}
