FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON += "-Dredfish-dump-log=enabled"
EXTRA_OEMESON += "-Dredfish-new-powersubsystem-thermalsubsystem=enabled"
EXTRA_OEMESON += "-Dredfish-provisioning-feature=enabled"
EXTRA_OEMESON += "-Dredfish-dbus-log=enabled"

# add "redfish-hostiface" group
GROUPADD_PARAM:${PN}:append = ";redfish-hostiface"

SRC_URI = "git://git.ami.com/core/ami-bmc/one-tree/core/bmcweb;branch=master;protocol=https;name=override;"
SRCREV_FORMAT = "override"
SRCREV_override = "d2b0cec4125b483f9f4fad8ccdbd24cbd26d56a7"

SRC_URI_NON_PFR = " file://0067-adding-support-for-HttpPushUriTargets.patch \
                    file://0242-Add-support-to-applytime-property.patch \
                    file://0180-Fixed-500-Internal-server-error-while-update-cpld-fw.patch \
                    file://0259-Fix-for-time-out-issue-in-FW-update.patch \
		            file://0260-Clear-cache-before-firmware-update-start-to-fix-out-.patch \
                    file://0270-UpdateService-should-block-HttpPushUriTargets-When-remove-anyone-of-the-SPI.patch \
"
SRC_URI:append = "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '', SRC_URI_NON_PFR, d)}"

# Remove the patches if 'meta-mgx' is in BBFILE_COLLECTIONS
#SRC_URI:remove = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'meta-mgx', SRC_URI_NON_PFR, '', d)}"

#SRC_URI_NM:append = "file://0083-modifing-the-error-when-initialization-mode-was-chan.patch \
#"
#SRC_URI_BHS:append = "file://0108-Adding-condition-to-Patch-Min-Value-not-greater-than.patch \
#                      file://0110-Fix-For-Pmt-Sensor-Not-listed-in-Redfish.patch \
#                      file://0118-removing-the-created-policy-get-calls-after-post.patch \
#                      file://0134-StaticLoadfactor-patch-in-Dynamic-mode-issue.patch \
#		      file://0136-support-domain-Capabilities-reset.patch \
#"
##SRC_URI:append:evb-ast2600   = "file://0179-Fixed-RestoreOptions-in-EVB.patch "
#
#SRC_URI_AMP:append = "file://0261-Resolving-500-error-form-systems-URI.patch \
#"
#
#SRC_URI_NVIDIA:append = "file://0261-resolving-nvidia-500-error-from-systems.patch \
#"
#
#EVB:append = "file://0179-Fixed-RestoreOptions-in-EVB.patch "  
#SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'evb', EVB, '', d)}"
#
#AST2700:append = "file://0236-Fix-for-Compilation-Error-in-AST2700-build.patch"
#SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'aspeed-sdk-layer', AST2700, '', d)}"
#
#SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'restricted', SRC_URI_NM, '', d)}"
#
#SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'mtmitchell-layer', SRC_URI_AMP, '', d)}"
#
#SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'meta-mgx', SRC_URI_NVIDIA, '', d)}"
#
#SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'bhs', "${@bb.utils.contains('BBFILE_COLLECTIONS', 'restricted', SRC_URI_BHS, '', d)}", '', d)}"
#
#SRC_URI_PFR = " file://0184-PFR-update-task-state-modifications-OT-2950.patch"
#SRC_URI:append = "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', SRC_URI_PFR, '', d)}"
#
# PFR
# HttpPushUriTargets and ApplyTime support are required for PFR
SRC_URI_PFR = " file://0067-adding-support-for-HttpPushUriTargets.patch \
                file://0242-Add-support-to-applytime-property-in-PFR.patch \
                file://0180-Fixed-500-Internal-server-error-while-update-cpld-fw.patch \
                file://0259-Fix-for-time-out-issue-in-FW-update.patch \
"
SRC_URI:append = "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', SRC_URI_PFR, '', d)}"
#EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '',' -Dhttp-body-limit=68 ', d)}"
#EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_INSTALL', 'nvme-mgmt', ' -Dnvme-enable-path=/xyz/openbmc_project/Nvme','', d)}"
#EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_INSTALL', 'nvmebasic-mgmt', ' -Dnvme-enable-path=/xyz/openbmc_project/NvmeBasic','', d)}"

EXTRA_OEMESON += "${@bb.utils.contains('BBFILE_COLLECTIONS', 'meta-mgx','-Dredfish-intel-feature=enabled','', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('BBFILE_COLLECTIONS', 'mtmitchell-layer', '-Dredfish-intel-feature=enabled', '', d)}"

DEPENDS += "phosphor-snmp"

