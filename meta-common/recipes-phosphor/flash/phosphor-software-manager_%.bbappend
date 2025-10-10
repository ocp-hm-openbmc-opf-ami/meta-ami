FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
#EXTRA_OEMESON += "-Dfwupd-script=enabled"

# Enable downstream autobump to fix sync build, can be removed later
# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI += "git://github.com/openbmc/phosphor-bmc-code-mgmt;branch=master;protocol=https"
#SRCREV = "30352a66bed92bbc1b12a2468d3ccb5eea500004"
SRCREV = "ee3ba93c873c54610ef369ca1fc849af3836120f"
SYSTEMD_SERVICE:${PN}-updater += "fwupd@.service"

EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '-Dpfr-update=enabled', '', d)}"
#EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-secboot', '-Dpfr-update=enabled', '', d)}"

SRC_URI += " \
    file://0002-Redfish-firmware-activation.patch \
    file://0004-Changed-the-condition-of-software-version-service-wa.patch \
    file://0005-Modified-firmware-activation-to-launch-fwupd.sh-thro.patch \
    file://0006-Modify-the-ID-of-software-image-updater-object-on-DB.patch \
    file://0007-Adding-StandBySpare-for-firmware-activation.patch \
    file://0008-item_updater-update-the-bmc_active-objectPath.patch \
    file://0009-Add-ApplyOptions-D-bus-property-under-Software.patch \
    file://0013-remove-image-file-on-pre-script-failures.patch \
    "

SRC_URI_PFR = " \
    file://0001-PFR-images-support-in-phosphor-software-manager.patch \
    file://0016-Process-PLDM-image-type.patch \
    file://0018-Fix-delete-image-by-ID-and-inhibit-removal-of-bmc_ac.patch \
    file://0019-Add-support-for-different-headers.patch \
    file://0020-Add-HttpPushUriTarget-and-busy-property-under-softwa.patch \
    "

SRC_URI += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', SRC_URI_PFR, '', d)}"
#SRC_URI += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-secboot', SRC_URI_PFR, '', d)}"

#pull down upstream recipe change, remove after upstream sync passes 
PACKAGECONFIG[side_switch_on_boot] = "-Dside-switch-on-boot=enabled, -Dside-switch-on-boot=disabled, cli11"
FILES:${PN}-side-switch += "\
    ${bindir}/phosphor-bmc-side-switch \
    "
SYSTEMD_SERVICE:${PN}:remove = "phosphor-bmc-side-switch.service"
SYSTEMD_SERVICE:${PN}-side-switch += "${@bb.utils.contains('PACKAGECONFIG', 'side_switch_on_boot', 'phosphor-bmc-side-switch.service', '', d)}"
SYSTEMD_SERVICE:${PN}:remove = "phosphor-bmc-side-switch.service"
