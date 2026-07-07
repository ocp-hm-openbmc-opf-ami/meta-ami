FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
EXTRA_OEMESON += "-Dfwupd-script=enabled"

SYSTEMD_SERVICE:${PN}-updater += "fwupd@.service"

EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', '-Dpfr-update=enabled', '', d)}"
EXTRA_OEMESON += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-secboot', '-Dpfr-update=enabled', '', d)}"

DBUS_SERVICE:${PN}-version += "${@bb.utils.contains_any('IMAGE_FSTYPES', 'intel-pfr intel-secboot', 'xyz.openbmc_project.Software.Version.service', '', d)}"

SRC_URI += " \
    file://0002-Redfish-firmware-activation.patch \
    file://0004-Changed-the-condition-of-software-version-service-wa.patch \
    file://0005-Modified-firmware-activation-to-launch-fwupd.sh-thro.patch \
    file://0006-Modify-the-ID-of-software-image-updater-object-on-DB.patch \
    file://0008-item_updater-update-the-bmc_active-objectPath.patch \
    file://0013-remove-image-file-on-pre-script-failures.patch \
    "

SRC_URI_PFR = " \
    file://0001-PFR-images-support-in-phosphor-software-manager.patch \
    file://0007-Adding-StandBySpare-for-firmware-activation.patch \
    file://0009-Add-ApplyOptions-D-bus-property-under-Software.patch \
    file://0016-Process-PLDM-image-type.patch \
    file://0018-Fix-delete-image-by-ID-and-inhibit-removal-of-bmc_ac.patch \
    file://0020-Add-HttpPushUriTarget-and-busy-property-under-softwa.patch \
    file://0020-Add-Support-for-SMM-Runtime-Update.patch \
    file://0020-Fix-for-Firmware-update-with-Software-Manager.patch \
    file://0021-Enabled-PFR-FW-update-handling-using-PFR-Image-Manager.patch \
    "

SRC_URI += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-pfr', SRC_URI_PFR, '', d)}"
SRC_URI += "${@bb.utils.contains('IMAGE_FSTYPES', 'intel-secboot', SRC_URI_PFR, '', d)}"
