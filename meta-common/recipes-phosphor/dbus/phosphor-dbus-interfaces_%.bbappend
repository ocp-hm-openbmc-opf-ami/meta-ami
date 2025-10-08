# The URI is required for the autobump script but keep it commented
# to not override the upstream value
# SRC_URI =  "git://github.com/openbmc/phosphor-dbus-interfaces.git;branch=master;protocol=https"
SRCREV = "800f708024fa74404f325b04892e276fdc118c62"
#SRCREV = "9012243e543abdc5851b7e878c17c991b2a2a8b7"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

INTEL_SRC_URI += "file://0007-ipmi-set-BIOS-id.patch \
            file://0010-Increase-the-default-watchdog-timeout-value.patch \
            file://0012-Add-RestoreDelay-interface-for-power-restore-delay.patch \
            file://0013-Add-ErrConfig.yaml-interface-for-processor-error-config.patch \
            file://0024-Add-the-pre-timeout-interrupt-defined-in-IPMI-spec.patch \
            file://0025-Add-PreInterruptFlag-properity-in-DBUS.patch \
            file://0026-Add-StandbySpare-support-for-software-inventory.patch \
            file://0028-MCTP-Daemon-D-Bus-interface-definition.patch \
            file://0029-Add-D-Bus-interfaces-for-PLDM-FW-update.patch \
            file://0030-Add-PLDM-version-purpose-enumeration.patch \
            file://0031-update-meson-build-files-for-control-and-bios.patch \
            file://0032-update-meson-build-for-MCTP-interfaces.patch \
            file://0033-update-meson-build-for-PLDM-FWU-interfaces.patch \
            file://0034-Add-username-property-to-SessionInfo-interface.patch \
            file://0035-Add-I3C-Binding-related-interfaces.patch \
            "

SRC_URI:append = "${@bb.utils.contains('BBFILE_COLLECTIONS', 'meta-ami', '',INTEL_SRC_URI, d)}"
EXTRA_OEMESON += "-Ddata_com_intel=true"
